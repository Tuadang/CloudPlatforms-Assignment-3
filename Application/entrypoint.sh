#!/bin/sh
if [ ! -d "migrations" ]; then
  flask db init
    flask db migrate -m "Initial migration"
fi
flask db upgrade
exec gunicorn -w 4 -b 0.0.0.0:8000 app:app