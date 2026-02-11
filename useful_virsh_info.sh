#!/usr/bin/env bash
set -euo pipefail

# List hostnames and IP addresses for running VMs.
# Requires QEMU guest agent for reliable hostnames and IPs via agent.

echo "== Running VMs with IPs (agent + DHCP lease sources) =="
virsh list --name | while read -r vm; do
	[[ -z "$vm" ]] && continue
	echo "--- $vm ---"
	virsh domifaddr "$vm" --source agent,lease || true
done

echo
echo "== Hostnames (requires guest agent) =="
virsh list --name | while read -r vm; do
	[[ -z "$vm" ]] && continue
	printf "%s: " "$vm"
	virsh domhostname "$vm" 2>/dev/null || echo "(unavailable)"
done

echo
echo "== DHCP leases from default libvirt network =="
virsh net-dhcp-leases default || true
