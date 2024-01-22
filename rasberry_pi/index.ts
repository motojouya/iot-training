import { mqtt5, iot } from "aws-iot-device-sdk-v2";
import { ICrtError } from "aws-crt";
import { once } from "events";
import { toUtf8 } from '@aws-sdk/util-utf8-browser';
import { scan } from './bluetooth';

type Args = { [index: string]: any };

const yargs = require('yargs');

yargs.command('*', false, (yargs: any) => {
    yargs.option('endpoint', {
        alias: 'e',
        description: 'Your AWS IoT custom endpoint, not including a port.',
        type: 'string',
        required: true
    })
    .option('cert', {
        alias: 'c',
        description: '<path>: File path to a PEM encoded certificate to use with mTLS.',
        type: 'string',
        required: true
    })
    .option('key', {
        alias: 'k',
        description: '<path>: File path to a PEM encoded private key that matches cert.',
        type: 'string',
        required: true
    })
    .option('topic', {
        alias: 't',
        description: 'mac address of bluetooth device',
        type: 'string',
        required: true
    })
    .option('device', {
        alias: 'd',
        description: 'mac address of bluetooth device',
        type: 'string',
        required: true
    })
    .option('macaddress', {
        alias: 'm',
        description: 'mac address of bluetooth device',
        type: 'string',
        required: true
    })
}, main).parse();

function creatClientConfig(args : any) : mqtt5.Mqtt5ClientConfig {
    let builder : iot.AwsIotMqtt5ClientConfigBuilder | undefined = undefined;

    builder = iot.AwsIotMqtt5ClientConfigBuilder.newDirectMqttBuilderWithMtlsFromPath(
        args.endpoint,
        args.cert,
        args.key
    );

    builder.withConnectProperties({
        keepAliveIntervalSeconds: 1200
    });

    return builder.build();
}

function createClient(args: any) : mqtt5.Mqtt5Client {

    let config : mqtt5.Mqtt5ClientConfig = creatClientConfig(args);

    console.log("Creating client for " + config.hostName);
    let client : mqtt5.Mqtt5Client = new mqtt5.Mqtt5Client(config);

    client.on('error', (error: ICrtError) => {
        console.log("Error event: " + error.toString());
    });

    client.on("messageReceived",(eventData: mqtt5.MessageReceivedEvent) : void => {
        console.log("Message Received event: " + JSON.stringify(eventData.message));
        if (eventData.message.payload) {
            console.log("  with payload: " + toUtf8(new Uint8Array(eventData.message.payload as ArrayBuffer)));
        }
    } );

    client.on('attemptingConnect', (eventData: mqtt5.AttemptingConnectEvent) => {
        console.log("Attempting Connect event");
    });

    client.on('connectionSuccess', (eventData: mqtt5.ConnectionSuccessEvent) => {
        console.log("Connection Success event");
        console.log ("Connack: " + JSON.stringify(eventData.connack));
        console.log ("Settings: " + JSON.stringify(eventData.settings));
    });

    client.on('connectionFailure', (eventData: mqtt5.ConnectionFailureEvent) => {
        console.log("Connection failure event: " + eventData.error.toString());
        if (eventData.connack) {
            console.log ("Connack: " + JSON.stringify(eventData.connack));
        }
    });

    client.on('disconnection', (eventData: mqtt5.DisconnectionEvent) => {
        console.log("Disconnection event: " + eventData.error.toString());
        if (eventData.disconnect !== undefined) {
            console.log('Disconnect packet: ' + JSON.stringify(eventData.disconnect));
        }
    });

    client.on('stopped', (eventData: mqtt5.StoppedEvent) => {
        console.log("Stopped event");
    });

    return client;
}

async function send(client : mqtt5.Mqtt5Client, topic, data) {

    const connectionSuccess = once(client, "connectionSuccess");
    client.start();
    await connectionSuccess;

    const qos0PublishResult = await client.publish({
        qos: mqtt5.QoS.AtMostOnce, // mqtt5.QoS.AtLeastOnce
        topicName: topic,
        payload: JSON.stringify(data),
    });
    console.log('QoS 0 Publish result: ' + JSON.stringify(qos0PublishResult));

    const stopped = once(client, "stopped");
    client.stop();
    await stopped;

    client.close();
}

async function main(args : Args){
    // make it wait as long as possible once the promise completes we'll turn it off.
    const timer = setTimeout(() => {}, 2147483647);
    let client : mqtt5.Mqtt5Client = createClient(args);
    const deviceName = args.device;
    const topic = args.topic;

    scan(args.macaddress, async (temperature, humidity, datetime) => {
        const data = {
          deviceName,
          temperature,
          humidity,
          datetime,
        };
        await send(client, topic, data);
        clearTimeout(timer);
        process.exit(0);
    });
}
