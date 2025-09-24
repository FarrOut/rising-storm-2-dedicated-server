#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "aws-cdk-lib";
import { Rs2VietnamServerStack } from "../lib/rs2vietnam-server-stack";
import { ImagePipelineStack } from "../lib/image-pipeline-stack";

const app = new cdk.App();

new ImagePipelineStack(app, "Rs2VietnamImagePipelineStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});

new Rs2VietnamServerStack(app, "Rs2VietnamServerStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});