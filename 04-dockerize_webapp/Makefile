IMAGE_NAME ?= flask-docker-webapp
IMAGE_TAG  ?= local
REGISTRY   ?= ghcr.io/<username>

.PHONY: install lint test run docker-build docker-run docker-push compose-up compose-down

install:
	pip install -r requirements-dev.txt

lint:
	flake8 app tests wsgi.py

test:
	pytest --cov=app -v

run:
	PORT=8080 python wsgi.py

docker-build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

docker-run:
	docker run --rm -p 8080:8080 $(IMAGE_NAME):$(IMAGE_TAG)

docker-push: docker-build
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

compose-up:
	docker compose up --build

compose-down:
	docker compose down
