# Google Batch Resource Scaling Guide

## Problem

When running Nextflow on Google Batch, processes that request more CPUs or memory than the default `machineType` will fail because:

1. **Google Batch does NOT automatically scale machine types** based on CPU/memory requests
2. Setting `process.cpus` or `process.memory` alone is not enough
3. Each process that needs more resources must explicitly specify a matching `machineType`

## Example Error

If your default is `n2-standard-8` (8 CPUs) and a process requests 32 CPUs:

```groovy
withName: 'bwa_align' {
    cpus = 32
    memory = "128 GB"
}
```

The process will crash trying to run 32 threads on an 8-CPU machine.

## Solution

This repository now includes **automatic resource scaling** via `config/google_batch_resources.config`.

### How It Works

The config file maps processes to appropriate machine types:

```groovy
process {
    // Default for all processes
    cpus = 4
    memory = '16 GB'
    machineType = 'n2-standard-4'

    // Label-based configuration
    withLabel: alignment {
        cpus = 8
        memory = '32 GB'
        machineType = 'n2-standard-8'
    }

    // Process-specific configuration
    withName: 'bwa_align' {
        cpus = 16
        memory = '64 GB'
        machineType = 'n2-standard-16'
    }
}
```

### Machine Type Selection Guide

Choose machine types based on your process requirements:

| vCPUs | Standard (4GB/vCPU) | High-Mem (8GB/vCPU) | High-CPU (0.9GB/vCPU) |
|-------|---------------------|---------------------|------------------------|
| 2     | n2-standard-2       | n2-highmem-2        | n2-highcpu-2          |
| 4     | n2-standard-4       | n2-highmem-4        | n2-highcpu-4          |
| 8     | n2-standard-8       | n2-highmem-8        | n2-highcpu-8          |
| 16    | n2-standard-16      | n2-highmem-16       | n2-highcpu-16         |
| 32    | n2-standard-32      | n2-highmem-32       | n2-highcpu-32         |
| 64    | n2-standard-64      | n2-highmem-64       | n2-highcpu-64         |
| 96    | n2-standard-96      | n2-highmem-96       | n2-highcpu-96         |

## Usage

### Method 1: Label-Based (Recommended)

Add labels to your process definitions:

```groovy
process bwa_align {
    label "alignment"  // Will use settings from 'withLabel: alignment'

    input:
    ...
}
```

Then configure in `config/google_batch_resources.config`:

```groovy
withLabel: alignment {
    cpus = 16
    memory = '64 GB'
    machineType = 'n2-standard-16'
}
```

### Method 2: Process-Specific

For individual process tuning:

```groovy
withName: 'specific_process' {
    cpus = 32
    memory = '128 GB'
    machineType = 'n2-highmem-32'
}
```

### Method 3: Dynamic Resources

Use `task.cpus` in your process scripts to automatically use allocated resources:

```groovy
process example {
    script:
    """
    bwa mem -t ${task.cpus} ...
    samtools sort -@ ${task.cpus} ...
    """
}
```

This is better than hardcoding `${params.threads}` because it adapts to the configured resources.

## Testing Resource Scaling

To verify a process uses the correct machine type:

1. Add a test process to your workflow:

```groovy
process test_resources {
    label "alignment"

    script:
    """
    echo "Allocated CPUs: ${task.cpus}"
    echo "Allocated Memory: ${task.memory}"
    echo "Machine Type: ${task.machineType}"
    nproc  # Should match allocated CPUs
    free -h  # Should show allocated memory
    """
}
```

2. Check the Google Batch console to confirm the job used the expected machine type

## Common Pitfalls

### ❌ Don't do this:

```groovy
// Setting CPUs without machineType
process.cpus = 32  // Will try to run on default 4-CPU machine!
```

### ✅ Do this instead:

```groovy
withName: 'my_process' {
    cpus = 32
    memory = '128 GB'
    machineType = 'n2-standard-32'
}
```

## Cost Optimization

- Start with smaller machine types and scale up only when needed
- Use labels to group similar processes
- Monitor your Cloud Billing to track costs per machine type
- Consider `n2-highcpu` for CPU-intensive, low-memory tasks
- Consider spot instances via `google.batch.maxSpotAttempts` (already enabled in this config)

## Further Reading

- [Nextflow Google Batch Executor](https://www.nextflow.io/docs/latest/google.html#google-batch)
- [Google Compute Engine Machine Types](https://cloud.google.com/compute/docs/machine-types)
- [Nextflow Process Directives](https://www.nextflow.io/docs/latest/process.html#directives)
