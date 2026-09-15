# Setup Graphics Drivers Orchestrator

## Overview

Convenience orchestrator that sequentially invokes NVIDIA and AMD GPU driver setup scripts (`setup-nvidia.sh` and `setup-amd.sh`). Both scripts feature hardware autodetection guards and execute only if corresponding physical GPU hardware is present, supporting single-GPU, hybrid (iGPU + dGPU), and multi-GPU configurations.

## Requirements

### Orchestration & Delegation

- **Sequential Execution**:
  1. Invokes `scripts/system/setup-nvidia.sh` to configure NVIDIA drivers, power management, and hybrid GPU switching (`switcheroo-control` / `prime-run`) if an NVIDIA GPU is detected.
  2. Invokes `scripts/system/setup-amd.sh` to configure AMD Mesa, Vulkan RADV, hardware acceleration, and codecs if an AMD GPU is detected.
- **Idempotency & Autodetection**: Inherits idempotency and automatic PCI device detection from the underlying scripts.
- **Error Handling**: Propagates failures with non-zero exit code if any underlying driver installation fails.

## Test Scenarios

### Feature: Graphics Drivers Setup

**Scenario: Successful execution of graphics driver orchestrator**

- **GIVEN** `setup-graphics.sh` is executed
- **WHEN** underlying setup scripts succeed or cleanly skip absent hardware
- **THEN** it executes `setup-nvidia.sh` and `setup-amd.sh` in order
- **AND** exits with return code 0

**Scenario: Failure propagation when an underlying setup script fails**

- **GIVEN** `setup-nvidia.sh` or `setup-amd.sh` returns a non-zero exit code
- **WHEN** `setup-graphics.sh` is executed
- **THEN** it halts execution immediately
- **AND** exits with a non-zero return code

**Scenario: Idempotent execution**

- **GIVEN** graphics drivers have already been configured
- **WHEN** `setup-graphics.sh` is executed again
- **THEN** it completes with exit code 0
