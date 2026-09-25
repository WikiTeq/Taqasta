#!/bin/bash

URL=$MONIT_SLACK_HOOK

if [ -z "$URL" ]
  then
    # Do nothing, exit silently
    exit 0
fi

COLOR=${MONIT_COLOR:-$([[ $MONIT_EVENT == *"Exists"* || $MONIT_EVENT == *"succeeded"*  ]] && echo good || echo danger)}
ICON=${MONIT_COLOR:-$([[ $MONIT_EVENT == *"Exists"* || $MONIT_EVENT == *"succeeded"* ]] && echo ✅ || echo ⚠️)}

PAYLOAD=$(MONIT_HOST="$MONIT_HOST" \
MONIT_SERVICE="$MONIT_SERVICE" \
MONIT_DATE="$MONIT_DATE" \
MONIT_EVENT="$MONIT_EVENT" \
MONIT_DESCRIPTION="$MONIT_DESCRIPTION" \
ICON="$ICON" \
COLOR="$COLOR" \
python3 -c 'import json, os
text = os.environ["ICON"] + " " + os.environ["MONIT_EVENT"] + ": " + os.environ["MONIT_DESCRIPTION"]
payload = {
    "attachments": [
        {
            "text": text,
            "color": os.environ["COLOR"],
            "mrkdwn_in": ["text"],
            "fields": [
                { "title": "Host", "value": os.environ["MONIT_HOST"], "short": True },
                { "title": "Service", "value": os.environ["MONIT_SERVICE"], "short": True },
                { "title": "Date", "value": os.environ["MONIT_DATE"], "short": True }
            ]
        }
    ]
}
print(json.dumps(payload))')

curl -s -X POST --data-urlencode "payload=$PAYLOAD" $URL
