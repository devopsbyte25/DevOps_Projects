import json

import pytest

from app.main import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config.update(TESTING=True)
    with app.test_client() as c:
        yield c


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_version(client):
    resp = client.get("/version")
    assert resp.status_code == 200
    assert "version" in resp.get_json()


def test_greet(client):
    resp = client.get("/api/greet/Alice")
    assert resp.status_code == 200
    assert resp.get_json()["message"] == "Hello, Alice!"


def test_time(client):
    resp = client.get("/api/time")
    assert resp.status_code == 200
    assert "server_time" in resp.get_json()


def test_echo(client):
    resp = client.post("/api/echo", data="hello world")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["you_sent"] == "hello world"
    assert body["length"] == 11


def test_items_crud(client):
    # initially empty (note: shared module state, so just check shape)
    resp = client.get("/api/items")
    assert resp.status_code == 200
    assert "items" in resp.get_json()

    # create
    resp = client.post(
        "/api/items",
        data=json.dumps({"name": "demo-item"}),
        content_type="application/json",
    )
    assert resp.status_code == 201
    created = resp.get_json()
    item_id = created["id"]
    assert created["name"] == "demo-item"

    # create without name -> 400
    resp = client.post("/api/items", data=json.dumps({}), content_type="application/json")
    assert resp.status_code == 400

    # delete
    resp = client.delete(f"/api/items/{item_id}")
    assert resp.status_code == 204

    # delete again -> 404
    resp = client.delete(f"/api/items/{item_id}")
    assert resp.status_code == 404
