# Drycc Valkey
[![Build Status](https://woodpecker.drycc.cc/api/badges/drycc/valkey/status.svg)](https://woodpecker.drycc.cc/drycc/valkey)

Drycc (pronounced DAY-iss) Workflow is an open source Platform as a Service (PaaS) that adds a developer-friendly layer to any [Kubernetes](http://kubernetes.io) cluster, making it easy to deploy and manage applications on your own servers.

## Usage

Different components use different db, as follows:

* `controller` use db 0
* `passport` use db 1
* `grafana` use db 2
* `manager` use db 10
* `helmbroker` use db 11

The above are the default configurations for each component.

## Description
A Container image for running standalone (not clustered) Valkey on a Kubernetes cluster.

[v2.18]: https://github.com/drycc/workflow/releases/tag/v2.18.0
