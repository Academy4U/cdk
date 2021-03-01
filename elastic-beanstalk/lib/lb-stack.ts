import {Vpc, IVpc, SecurityGroup, Port, Peer} from '@aws-cdk/aws-ec2';
import {ApplicationLoadBalancer, ListenerAction} from '@aws-cdk/aws-elasticloadbalancingv2';
import {Stack, Construct, CfnOutput, Environment} from '@aws-cdk/core';

export interface ALBStackProps {
  readonly vpc: IVpc;
  readonly env?: Environment;
  readonly tags?: {
    [key: string]: string;
  };
}

/**
 * 
 */
export class LoadBalancerStack extends Stack {
  readonly vpc: IVpc;
  readonly albSecurityGroup: SecurityGroup;
  readonly lb: ApplicationLoadBalancer;
  constructor(app: Construct, id: string, props: ALBStackProps) {
    super(app, id, props);
    
    this.vpc = props.vpc;

    this.albSecurityGroup = new SecurityGroup(this, id + '-albSG', {
      allowAllOutbound: true,
      securityGroupName: id + '-alb-sg',
      vpc: this.vpc,
    });
    this.albSecurityGroup.addIngressRule(Peer.anyIpv4(), Port.tcp(80));
  // albSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443));

    this.lb = new ApplicationLoadBalancer(this, id + '-alb', {
      vpc: this.vpc,
      internetFacing: true,
      securityGroup: this.albSecurityGroup // Optional - will be automatically created otherwise
    });

    const listener = this.lb.addListener(id + '-albListener', {
      port: 80,
      // 'open: true' is the default, you can leave it out if you want. Set it to 'false' and use `listener.connections` if you want to be selective
      // about who can access the load balancer.
      open: true,
      defaultAction: ListenerAction.redirect({protocol: 'HTTP', port: '80',path:'/' }),
    });

  }
}