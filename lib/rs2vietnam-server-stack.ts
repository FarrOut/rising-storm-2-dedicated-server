import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as ssm from 'aws-cdk-lib/aws-ssm';

export class Rs2VietnamServerStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const sshPublicKeyPath = this.node.tryGetContext('sshPublicKeyPath');
    const sshPublicKey = this.node.tryGetContext('sshPublicKey');
    
    if (!sshPublicKeyPath && !sshPublicKey) {
      throw new Error('SSH public key must be provided via context: -c sshPublicKeyPath="/path/to/key.pub" or -c sshPublicKey="ssh-rsa AAAA..."');
    }
    
    let publicKeyContent = sshPublicKey;
    if (sshPublicKeyPath) {
      const fs = require('fs');
      const path = require('path');
      const expandedPath = sshPublicKeyPath.startsWith('~') 
        ? path.join(require('os').homedir(), sshPublicKeyPath.slice(1))
        : sshPublicKeyPath;
      publicKeyContent = fs.readFileSync(expandedPath, 'utf8').trim();
    }

    // Create VPC
    const vpc = new ec2.Vpc(this, 'Rs2VietnamVpc', {
      maxAzs: 2,
      natGateways: 0,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
      ],
    });

    // Create key pair from SSH public key
    const keyPair = new ec2.CfnKeyPair(this, 'Rs2VietnamKeyPair', {
      keyName: 'rs2vietnam-keypair',
      publicKeyMaterial: publicKeyContent,
    });

    // Security group for game server
    const securityGroup = new ec2.SecurityGroup(this, 'Rs2VietnamSecurityGroup', {
      vpc,
      description: 'Security group for RS2:Vietnam dedicated server',
      allowAllOutbound: true,
    });

    // SSH access
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(22), 'SSH access');
    
    // MOSH access (UDP 60000-61000)
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.udpRange(60000, 61000), 'MOSH access');
    
    // RS2:Vietnam game ports
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.udp(7777), 'RS2:Vietnam game port');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.udp(27015), 'RS2:Vietnam query port');
    securityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(8080), 'RS2:Vietnam web admin port');

    // Get AMI ID from Parameter Store or use default
    const amiId = this.node.tryGetContext('amiId') || 
      ssm.StringParameter.valueForStringParameter(this, '/rs2vietnam/ami-id');

    // Launch template with spot instances
    const launchTemplate = new ec2.LaunchTemplate(this, 'Rs2VietnamLaunchTemplate', {
      machineImage: ec2.MachineImage.genericLinux({ [this.region]: amiId }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.C5, ec2.InstanceSize.LARGE),
      keyPair: ec2.KeyPair.fromKeyPairName(this, 'ImportedKeyPair', keyPair.keyName!),
      securityGroup,
      userData: ec2.UserData.forLinux(),
      spotOptions: {
        maxPrice: 0.10,
      },
    });

    launchTemplate.userData?.addCommands(
      'sudo systemctl start rs2vietnam.service'
    );

    // Auto Scaling Group
    new autoscaling.AutoScalingGroup(this, 'Rs2VietnamAsg', {
      vpc,
      launchTemplate,
      minCapacity: 0,
      maxCapacity: 5,
      desiredCapacity: 1,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // Output the security group ID for reference
    new cdk.CfnOutput(this, 'SecurityGroupId', {
      value: securityGroup.securityGroupId,
      description: 'Security Group ID for RS2:Vietnam server',
    });
  }
}