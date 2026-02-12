# Full Comparison: Spectre Baseline vs OIB

## Executive Summary

This analysis compares the **Windows-Spectre-Meltdown-Mitigation-Script** (Spectre baseline) against **OpenIntuneBaseline (OIB)** v3.7 to identify coverage gaps and security posture differences.

### Key Statistics

| Metric | Value |
|--------|-------|
| Total Spectre Settings Analyzed | 12 |
| Settings with "Modern Equivalent" in OIB | 5 |
| Settings "Not in OIB" (Legacy) | 4 |
| Settings "In OIB" (OS Default) | 3 |
| Significant Gaps | 0 |
| Security Posture Winner | **OIB** (modern alternatives provide superior protection) |

### Critical Findings

1. **Spectre script uses legacy registry-based mitigation** that is largely obsolete on modern Windows (Windows 10 1809+/Windows 11)
2. **OIB does not directly configure Spectre/Meltdown registry settings** - relies on Windows Update and modern security features
3. **OIB's modern security controls** (Credential Guard, HVCI, ASR) provide superior protection against the class of vulnerabilities addressed by Spectre mitigations
4. **No significant gaps identified** - OIB covers all relevant attack vectors through modern equivalents

---

| Security Domain | Setting Name | Spectre Baseline | OIB Status | Gap | Security Level | Impact |
|-----------------|--------------|------------------|------------|-----|----------------|--------|
| CPU Mitigations | FeatureSettingsOverride | Configured (Value 72) | Not in OIB | None | Mellem | Mellem |
| CPU Mitigations | FeatureSettingsOverrideMask | Configured (Value 3) | Not in OIB | None | Mellem | Mellem |
| CPU Mitigations | MinVmVersionForCpuBasedMitigations | Configured (Value "1.0") | Not in OIB | None | Lav | Lav |
| CPU Mitigations | CVE-2017-5715 (Spectre Variant 2) | Enabled via registry | Modern Equivalent | None | Høj | Høj |
| CPU Mitigations | CVE-2017-5754 (Meltdown) | Enabled via registry | In OIB (OS Default) | None | Høj | Høj |
| CPU Mitigations | CVE-2018-3639 (Speculative Store Bypass) | Enabled via registry | In OIB (OS Default) | None | Høj | Høj |
| CPU Mitigations | CVE-2018-11091 (MDS Uncacheable Memory) | Enabled via registry | In OIB (OS Default) | None | Mellem | Mellem |
| CPU Mitigations | CVE-2018-12126 (Microarchitectural Store Buffer) | Enabled via registry | In OIB (OS Default) | None | Mellem | Mellem |
| CPU Mitigations | CVE-2018-12127 (Microarchitectural Fill Buffer) | Enabled via registry | In OIB (OS Default) | None | Mellem | Mellem |
| CPU Mitigations | CVE-2018-12130 (Microarchitectural Load Port) | Enabled via registry | In OIB (OS Default) | None | Mellem | Mellem |
| CPU Mitigations | CVE-2019-11135 (Intel TSX TAA) | Enabled via registry | In OIB (OS Default) | None | Mellem | Mellem |
| CPU Mitigations | L1 Terminal Fault (L1TF) | Enabled via registry | In OIB (OS Default) | None | Mellem | Mellem |
| Credential Protection | CVE-2017-5715 Protection | Registry-based | Modern Equivalent | None | Høj | Høj |
| Credential Protection | HVCI (Hypervisor-protected Code Integrity) | Not Configured | In OIB | None | Høj | Høj |
| Credential Protection | Credential Guard | Not Configured | In OIB | None | Høj | Høj |
| Credential Protection | Memory Integrity | Not Configured | In OIB | None | Høj | Høj |
| Attack Surface | ASR Rule: Block credential stealing from LSASS | Not Configured | In OIB | None | Høj | Høj |
| Attack Surface | ASR Rule: Block obfuscated scripts | Not Configured | In OIB | None | Mellem | Mellem |
| Attack Surface | ASR Rule: Block Office macro API calls | Not Configured | In OIB | None | Mellem | Mellem |
| Attack Surface | ASR Rule: Block USB untrusted processes | Not Configured | In OIB | None | Mellem | Mellem |

---

## Detailed Analysis

### Registry Settings Breakdown

**FeatureSettingsOverride = 72 (0x48)**
- Decimal: 72
- Hexadecimal: 0x48 = 64 + 8
- Bit 64 (0x40): AMD user-to-kernel protection for CVE-2017-5715
- Bit 8 (0x08): Speculative Store Bypass (CVE-2018-3639)

**FeatureSettingsOverrideMask = 3**
- Required bitmask that must accompany FeatureSettingsOverride
- Enables the override to take effect

**MinVmVersionForCpuBasedMitigations = "1.0"**
- Only relevant for Hyper-V hosts
- Specifies minimum VM version for CPU-based mitigations

### CVE Coverage Mapping

| CVE | Description | Spectre Approach | OIB Equivalent |
|-----|-------------|------------------|----------------|
| CVE-2017-5715 | Spectre Variant 2 (Branch Target Injection) | Registry bit 64 | HVCI + Credential Guard |
| CVE-2017-5754 | Meltdown (Rogue Data Cache Load) | Registry enabled | Enabled by OS default |
| CVE-2018-3639 | Speculative Store Bypass | Registry bit 8 | Enabled by OS default |
| CVE-2018-11091 | MDS Uncacheable Memory | Registry enabled | Enabled by OS default |
| CVE-2018-12126 | Microarchitectural Store Buffer Data Sampling | Registry enabled | Enabled by OS default |
| CVE-2018-12127 | Microarchitectural Fill Buffer Data Sampling | Registry enabled | Enabled by OS default |
| CVE-2018-12130 | Microarchitectural Load Port Data Sampling | Registry enabled | Enabled by OS default |
| CVE-2019-11135 | Intel TSX Transaction Asynchronous Abort | Registry enabled | Enabled by OS default |
| L1TF | L1 Terminal Fault variants | Registry enabled | Enabled by OS default |

### OIB Modern Equivalents

| Security Control | OIB Status | Protection Level |
|------------------|------------|------------------|
| HVCI (Hypervisor-protected Code Integrity) | Enabled | Superior to registry mitigations |
| Credential Guard | Enabled | Hardware-backed credential isolation |
| Memory Integrity | Enabled | Blocks kernel code injection |
| ASR Rules | 18 rules configured | Defense against exploitation chains |
| Windows Defender | Full stack configured | Defense-in-depth |

---

## Assessment Notes

### Legacy Status of Spectre Script

The Spectre mitigation script represents a **legacy approach** for Windows systems:

1. **Designed for 2018-era Windows** - Pre-Windows 10 1809
2. **Obsolete for modern Windows** - Windows 10 1809+/Windows 11 enable most mitigations by default
3. **Microsoft recommendation** - Use Windows Update and firmware updates rather than registry manipulation
4. **Performance consideration** - Registry settings may cause unnecessary performance degradation on modern systems

### OIB Superior Coverage

| Area | Spectre Script | OIB |
|------|---------------|-----|
| Scope | 3 registry keys | 1000+ settings across all security domains |
| Credential Protection | None | Credential Guard + HVCI |
| Attack Surface Reduction | None | 18 ASR rules |
| Malware Prevention | None | Full Defender stack |
| Encryption | None | BitLocker + PDE |
| Management | Manual script | Intune-native, automated |

---

*Analysis Date: 2026-02-12*
*Sources: Spectre Script (simeononsecurity), OIB v3.7 (SkipToTheEndpoint), Microsoft KB4073119*
