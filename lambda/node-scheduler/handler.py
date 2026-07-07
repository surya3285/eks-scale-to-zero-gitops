"""Sets the desired/min/max size of an EKS managed node group.

Invoked by two EventBridge Scheduler schedules (scale-up, scale-down), each
passing a fixed JSON payload as the event -- see the scaling-scheduler
Terraform module for the schedule definitions and payload shape:

    {
      "cluster_name": "eks-scale-to-zero-dev",
      "nodegroup_name": "workload",
      "desired_size": 2,
      "min_size": 0,
      "max_size": 3
    }

EKS only allows one in-flight config update per node group at a time. If a
previous update (e.g. an addon version bump) is still propagating,
update_nodegroup_config raises ResourceInUseException. Scale-up and
scale-down run ~12 hours apart, so a collision is unlikely; if it does
happen, the call fails, CloudWatch records a Lambda error, and the node
group simply keeps its current size until the next scheduled run.
"""

import boto3

eks = boto3.client("eks")


def handler(event, context):
    cluster_name = event["cluster_name"]
    nodegroup_name = event["nodegroup_name"]
    scaling_config = {
        "desiredSize": event["desired_size"],
        "minSize": event["min_size"],
        "maxSize": event["max_size"],
    }

    response = eks.update_nodegroup_config(
        clusterName=cluster_name,
        nodegroupName=nodegroup_name,
        scalingConfig=scaling_config,
    )

    print(
        f"Requested scalingConfig={scaling_config} for "
        f"{cluster_name}/{nodegroup_name}, updateId="
        f"{response['update']['id']}"
    )

    return {"updateId": response["update"]["id"], "scalingConfig": scaling_config}
