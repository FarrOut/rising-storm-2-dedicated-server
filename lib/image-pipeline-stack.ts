import * as cdk from "aws-cdk-lib";
import { ImagePipeline } from "cdk-image-pipeline";
import { Construct } from "constructs";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as ssm from "aws-cdk-lib/aws-ssm";

export class ImagePipelineStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const machineImage = ec2.MachineImage.lookup({
      name: 'ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*',
      owners: ['099720109477'], // Canonical
    });
    const machineImageConfig = machineImage.getImage(this);
    const amiId = machineImageConfig.imageId;

    const imagePipeline = new ImagePipeline(this, "Rs2VietnamImagePipeline", {
      components: [
        {
          document: "./lib/components/steamcmd.yml",
          name: "steamcmd",
          version: "0.1.1",
        },
        {
          document: "./lib/components/rs2vietnam.yml",
          name: "rs2vietnam",
          version: "0.1.1",
        },
      ],
      parentImage: amiId,
      ebsVolumeConfigurations: [
        {
          deviceName: "/dev/xvda",
          ebs: {
            encrypted: true,
            volumeSize: 30,
            volumeType: "gp3",
          },
        },
      ],
    });
  }
}
