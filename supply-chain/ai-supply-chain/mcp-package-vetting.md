# AI Supply Chain — MCP Package Vetting

**Framework:** LLM05 (Supply Chain) / LLM07 (Insecure Plugin Design) / T1195.002

## The Problem

MCP servers are npm or PyPI packages that run locally and get full tool access to the agent's environment. A malicious package can declare tools that exfiltrate data, execute arbitrary code, or manipulate agent behavior. There is no app store review — you are responsible for vetting.

---

## Vetting Process (before installing any MCP server)

### Step 1 — Identity Check
- Who published it? Individual or org?
- Is the GitHub repo linked from the package registry?
- How many downloads, stars, contributors?
- Any recent suspicious commits?

### Step 2 — Tool Declaration Review
Read the MCP server's tool definitions before installing.
```bash
# For npm packages — inspect before install
npm pack <package-name>
tar -xf <package>.tgz
cat package/src/index.* | grep -A 10 "name:"
```
- Are declared permissions minimal for the stated purpose?
- Does a `read_file` tool also make outbound HTTP calls?
- Are there undeclared capabilities?

### Step 3 — Network Behavior
```bash
# Run in a network-sandboxed container and observe outbound connections
# Any connection to non-obvious endpoints = flag
```

### Step 4 — Pin and Sign
```bash
# Pin to exact version + integrity hash
npm install <package>@<version> --save-exact

# Verify integrity
npm audit
```

---

## Vetting Log

| Package | Version | Publisher | Tools Declared | Network | Decision | Date |
|---|---|---|---|---|---|---|
| | | | | | | |

---

## Red Flags — Immediate Reject

- Tool names that shadow built-in tools (`read_file`, `execute_command`)
- Outbound HTTP calls in tool implementations
- Obfuscated source
- Publisher with no public identity
- Package that requests filesystem or shell access for a task that doesn't require it
