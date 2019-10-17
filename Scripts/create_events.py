import sys
import logging
import datetime
import time
import os
import uuid
import argparse 
import json

from azure.eventhub import EventHubClient, Sender, EventData

logger = logging.getLogger("azure")

parser = argparse.ArgumentParser(description="Please supply eventhub name and access key.")
parser.add_argument('--eventhub')
parser.add_argument('--key')
args = parser.parse_args()

if not args.eventhub:
    raise ValueError("No Event Hub NameSpace supplied.")

if not args.key:
    raise ValueError("No Event Hub Key supplied.")


USER = "RootManageSharedAccessKey"
ADDRESS = "amqps://" + args.eventhub + ".servicebus.windows.net/events"
KEY = args.key

try:
    # Create Event Hubs client
    client = EventHubClient(ADDRESS, debug=False, username=USER, password=KEY)
    sender = client.add_sender(partition="0")
    client.run()
    
    try:
        localtime = time.asctime( time.localtime(time.time()) )

        id = str(uuid.uuid4())
        
        msg = {
            "keyId": id[:8],
            "key": "This is a test string",
            "host": os.name,
            "timeStamp": localtime,
        }

        data = EventData(json.dumps(msg))
        sender.send(data)
    except:
        raise
    finally:
        client.stop()

except KeyboardInterrupt:
    pass