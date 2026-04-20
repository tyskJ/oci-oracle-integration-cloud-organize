"""
Compute Instance 停止 OCI Functions
"""

import io
import json
import logging
import os
import oci

from fdk import response
    
"""
EntryPoint
"""
def handler(ctx, data: io.BytesIO = None):
    logger = logging.getLogger()
    logger.info("Compute Instance Stoped")
    """0. 環境変数チェック"""
    compartment_name = os.getenv("COMPARTMENT_NAME")
    instance_state = os.getenv("INSTANCE_STATE")
    tag_namespace = os.getenv("TAG_NAMESPACE")
    defined_tag_key = os.getenv("DEFINED_TAG_KEY")
    defined_tag_value = os.getenv("DEFINED_TAG_VALUE")
    if not compartment_name:
        return error_response(ctx, "COMPARTMENT_NAME environment variable is not set")
    if not instance_state:
        return error_response(ctx, "INSTANCE_STATE environment variable is not set")
    if not tag_namespace:
        return error_response(ctx, "TAG_NAMESPACE environment variable is not set")
    if not defined_tag_key:
        return error_response(ctx, "DEFINED_TAG_KEY environment variable is not set")
    if not defined_tag_value:
        return error_response(ctx, "DEFINED_TAG_VALUE environment variable is not set")
    """1. Resource Principal Signer"""
    try:
        signer = oci.auth.signers.get_resource_principals_signer()
        logger.info("Resource Principal Signer acquired successfully")
    except Exception as e:
        logger.error(f"Failed to get Resource Principal Signer: {e}")
        return error_response(ctx, str(e), 500)
    """2. Compute Client"""
    try:
        compute_client = oci.core.ComputeClient(
            config={},
            signer=signer
        )
        logger.info("ComputeClient initialized")
    except Exception as e:
        logger.error(f"Failed to initialize ComputeClient: {e}")
        return error_response(ctx, str(e), 500)
    """3. Compute Instance IDs 取得"""
    try:
        identity_client = oci.identity.IdentityClient(
            config={},
            signer=signer
        )
        tenancy_id = signer.tenancy_id
        resp = identity_client.list_compartments(
            compartment_id=tenancy_id,
            compartment_id_in_subtree=True,
            lifecycle_state="ACTIVE",
            name=compartment_name
        )
        compartment_id = resp.data[0].id
        resp = compute_client.list_instances(
            compartment_id=compartment_id,
            lifecycle_state=instance_state
        ).data
        result_ids = []
        if resp:
            result_ids = [
                obj.id
                for obj in resp
                if getattr(obj, "defined_tags", {}).get(tag_namespace, {}).get(defined_tag_key) == defined_tag_value
            ]
        else:
            return success_response(
                ctx,
                {
                    "message": "Instance Already Stopped."
                },
                202
            )
    except oci.exceptions.ServiceError as e:
        logger.error(
            "Get Compute Instance IDs failed: "
            f"status={e.status}, code={e.code}, message={e.message}"
        )
        return error_response(ctx, e.message, e.status)
    except Exception as e:
        logger.error(f"Unexpected error during get compute instance ids: {e}")
        return error_response(ctx, str(e), 500)
    """4. Compute Instance State 変更"""
    try:
        for instance_id in result_ids:
            logger.info(f"Gracefully shuts down Instance: {instance_id}")
            compute_client.instance_action(
                instance_id=instance_id,
                action="SOFTSTOP"
            )
            logger.info(f"Finished Gracefully shuts down Instace: {instance_id}")
        return success_response(
            ctx,
            {
                "message": "Success Gracefully shuts down Instances."
            },
            202
        )
    except oci.exceptions.ServiceError as e:
        logger.error(
            "Update Compute Instance State failed: "
            f"status={e.status}, code={e.code}, message={e.message}"
        )
        return error_response(ctx, e.message, e.status)
    except Exception as e:
        logger.error(f"Unexpected error during update compute instance state: {e}")
        return error_response(ctx, str(e), 500)

"""
Common Func
"""
def success_response(ctx, data: dict, status_code: int=200):
    """成功レスポンスを返す"""
    return response.Response(
        ctx,
        response_data=json.dumps(
            data, 
            ensure_ascii=False, 
            indent=2
        ),
        headers={"Content-Type": "application/json"},
        status_code=status_code
    )

def error_response(ctx, error_message: str, status_code: int=500):
    """エラーレスポンスを返す"""
    return response.Response(
        ctx,
        response_data=json.dumps(
            {"error": error_message}, 
            ensure_ascii=False
        ),
        headers={"Content-Type": "application/json"},
        status_code=status_code
    )