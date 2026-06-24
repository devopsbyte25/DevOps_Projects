"""
Demo Flask web app for a DevOps / Docker / CI-CD project.

Implemented endpoints:
  GET    /health                 -> liveness/readiness probe
  GET    /version                -> app version (from APP_VERSION env var)
  GET    /api/greet/<name>       -> simple greeting
  GET    /api/time               -> current server UTC time
  POST   /api/echo               -> echoes back request body
  GET    /api/items              -> list in-memory items
  POST   /api/items              -> create an item ({"name": "..."})
  DELETE /api/items/<id>         -> delete an item by id
"""

import os
from datetime import datetime, timezone

from flask import Flask, jsonify, request

# Simple in-memory "datastore" just to demonstrate multiple HTTP methods.
ITEMS = []
_next_id = 1


def create_app() -> Flask:
    app = Flask(__name__)

    @app.get("/health")
    def health():
        return jsonify(status="ok", time=datetime.now(timezone.utc).isoformat())

    @app.get("/version")
    def version():
        return jsonify(version=os.environ.get("APP_VERSION", "dev"))

    @app.get("/api/greet/<name>")
    def greet(name: str):
        return jsonify(message=f"Hello, {name}!")

    @app.get("/api/time")
    def server_time():
        return jsonify(server_time=datetime.now(timezone.utc).isoformat())

    @app.post("/api/echo")
    def echo():
        data = request.get_data(as_text=True)
        return jsonify(you_sent=data, length=len(data))

    @app.get("/api/items")
    def list_items():
        return jsonify(items=ITEMS)

    @app.post("/api/items")
    def create_item():
        global _next_id
        payload = request.get_json(silent=True) or {}
        name = payload.get("name")
        if not name:
            return jsonify(error="name is required"), 400
        item = {"id": _next_id, "name": name}
        ITEMS.append(item)
        _next_id += 1
        return jsonify(item), 201

    @app.delete("/api/items/<int:item_id>")
    def delete_item(item_id: int):
        global ITEMS
        before = len(ITEMS)
        ITEMS = [i for i in ITEMS if i["id"] != item_id]
        if len(ITEMS) == before:
            return jsonify(error="not found"), 404
        return "", 204

    return app


app = create_app()
