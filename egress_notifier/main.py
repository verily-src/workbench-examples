from flask import Flask, request, jsonify
import os
import logging
from datetime import datetime
from email_notifier import EmailNotifier
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def verify_token(auth_header):
    """Verify the JWT token from the Authorization header"""
    if not auth_header:
        return None

    try:
        # Extract token from "Bearer <token>"
        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return None

        token = parts[1]

        # Verify the token
        # For Cloud Run, the audience should be the service URL
        request_obj = google_requests.Request()
        claims = id_token.verify_oauth2_token(token, request_obj)

        logger.info(f"Authenticated request from: {claims.get('email', 'unknown')}")
        return claims

    except Exception as e:
        logger.warning(f"Token verification failed: {str(e)}")
        return None


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint for Cloud Run"""
    return jsonify({"status": "healthy"}), 200


@app.route('/egress-notification', methods=['POST'])
def handle_egress_notification():
    """Handle incoming egress event notifications"""
    # Verify authentication
    auth_header = request.headers.get('Authorization')
    claims = verify_token(auth_header)

    if not claims:
        logger.warning(f"Unauthorized request from {request.remote_addr}")
        return jsonify({
            "error": "Unauthorized",
            "message": "Valid authentication token required"
        }), 401

    try:
        data = request.get_json()

        # Validate required fields
        required_fields = [
            'incidentCount', 'vwbWorkspaceId', 'vwbEgressEventId',
            'egressMib', 'egressMibThreshold', 'gcpProjectId',
            'vmName', 'timeWindowDuration', 'timeWindowStart', 'userEmail'
        ]

        missing_fields = [field for field in required_fields if field not in data]
        if missing_fields:
            logger.warning(f"Missing required fields: {missing_fields}")
            return jsonify({
                "error": "Missing required fields",
                "missing_fields": missing_fields
            }), 400

        # Log the event
        logger.info(f"Egress event received for workspace {data['vwbWorkspaceId']}, "
                   f"user {data['userEmail']}, egress {data['egressMib']} MiB")

        # Send email notification
        notifier = EmailNotifier()
        notifier.send_egress_notification(data)

        return jsonify({
            "status": "success",
            "message": "Notification sent successfully",
            "eventId": data['vwbEgressEventId']
        }), 200

    except Exception as e:
        logger.error(f"Error processing egress notification: {str(e)}", exc_info=True)
        return jsonify({
            "error": "Internal server error",
            "message": str(e)
        }), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
