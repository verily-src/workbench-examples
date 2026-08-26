import os
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class EmailNotifier:
    """Handles email notifications for egress events"""

    def __init__(self):
        self.admin_emails = os.environ.get('ADMIN_EMAILS', '').split(',')


    def format_timestamp(self, unix_epoch_ms):
        """Convert Unix epoch milliseconds to readable datetime"""
        try:
            timestamp = datetime.fromtimestamp(unix_epoch_ms / 1000.0)
            return timestamp.strftime('%Y-%m-%d %H:%M:%S UTC')
        except Exception as e:
            logger.warning(f"Error formatting timestamp {unix_epoch_ms}: {str(e)}")
            return str(unix_epoch_ms)

    def create_email_body(self, data):
        """Create email body from egress event data"""
        return f"""Dear User,

This is an automated notification to inform you about an egress event that has occurred in your Workbench environment.

Event Details:
- Incident Count: {data['incidentCount']}
- Workbench Workspace ID: {data['vwbWorkspaceId']}
- Egress Event ID: {data['vwbEgressEventId']}
- Egress Data (MiB): {data['egressMib']}
- Egress Threshold (MiB): {data['egressMibThreshold']}
- GCP Project ID: {data['gcpProjectId']}
- VM Name: {data['vmName']}
- Time Window Duration (seconds): {data['timeWindowDuration']}
- Time Window Start (Unix epoch milliseconds): {data['timeWindowStart']}
- Time Window Start (Readable): {self.format_timestamp(data['timeWindowStart'])}
- User Email: {data['userEmail']}

Please review this event and take any necessary actions.

Sincerely,
Your GP2 Data Custodian Team
"""

    def send_egress_notification(self, data):
        """Send egress notification email using Mailgun API"""
        # Determine recipients
        recipients = [data['userEmail']]
        if self.admin_emails and self.admin_emails[0]:
            recipients.extend(self.admin_emails)

        # Create email content
        subject = f"Egress Event Alert - Workspace {data['vwbWorkspaceId']}"
        body = self.create_email_body(data)
    
        notification_email = f"Mock email notification:\nTo: {', '.join(recipients)}\nSubject: {subject}\n\n{body}"

        # TODO: Send notification_email using your provider of choice (e.g. mailgun, sendgrid, etc.)
        logger.info(notification_email.replace("\n", " "))
