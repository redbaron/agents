# JSON File Operations

## Working with JSON Files

When working with JSON **files** (reading, writing, validating, processing files on disk), use `jq` as the standard tool.

For validating JSON files:
```bash
jq . file.json
```

For processing JSON files:
```bash
jq '.key' file.json
```

**Note**: This applies to file operations only. For JSON data in conversation context, use your built-in understanding without needing external tools.
