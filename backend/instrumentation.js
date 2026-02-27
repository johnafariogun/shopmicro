/*instrumentation.js*/
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');

const sdk = new NodeSDK({
    traceExporter: new OTLPTraceExporter({
        // optional - default url is http://localhost:4317
        // url: 'http://otel-collector:4317',
    }),
    metricReader: new PeriodicExportingMetricReader({
        exporter: new OTLPMetricExporter({
            // url: 'http://otel-collector:4317',
        }),
    }),
    instrumentations: [getNodeAutoInstrumentations()],
});

// ... (keep the imports and sdk configuration the same) ...

// REPLACE sdk.start() WITH THIS:
try {
    sdk.start();
    console.log('OpenTelemetry SDK started successfully');
} catch (error) {
    console.error('Error initializing OpenTelemetry SDK. Backend will start without tracing.', error);
}

// Optional but highly recommended: Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
console.log('OpenTelemetry SDK started');
