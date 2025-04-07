import { TerraformVariable, VariableType } from "cdktf";
import { Construct } from "constructs";
import { Group } from "./.gen/providers/ansible/group";
import { Host } from "./.gen/providers/ansible/host";
import { Lxc } from "./.gen/providers/proxmox/lxc";
import { ProxmoxProvider } from "./.gen/providers/proxmox/provider";
import { Password } from "./.gen/providers/random/password";
import { PrivateKey } from "./.gen/providers/tls/private-key";

type Vars = {
    pmApiTokenName: TerraformVariable;
    pmApiUser: TerraformVariable;
    pmApiTokenSecret: TerraformVariable;
    pmHost: TerraformVariable
    pmPassword: TerraformVariable;
    pmUser: TerraformVariable;
}

const SERVER_NODE_COUNT = 1;
const AGENT_NODE_COUNT = 2;

export const defineProxmox = (stack: Construct, {
    pmApiTokenName,
    pmApiUser,
    pmApiTokenSecret,
    pmHost,
    pmUser,
    pmPassword
}: Vars) => {
    const provider = new ProxmoxProvider(stack, "proxmox", {
        pmApiTokenId:
            "${" + pmApiUser.value + "}!${" + pmApiTokenName.value + "}",
        pmApiTokenSecret: pmApiTokenSecret.stringValue,
        pmApiUrl: "http://${" + pmHost.value + "}:8006/api2/json",
        pmTlsInsecure: true,
    });

    const lxcPassword = new Password(stack, "lxc_password", {
        length: 16,
        special: true,
    });
    const lxcSshKey = new PrivateKey(stack, "lxc_ssh_key", {
        algorithm: "RSA",
        rsaBits: 4096,
    });

    new Host(stack, "proxmox_host", {
        groups: ["proxmox"],
        name: "proxmox_host",
        variables: {
            ansible_host: pmHost.stringValue,
            ansible_ssh_pass: pmPassword.stringValue,
            ansible_user: pmUser.stringValue,
        },
    });

    const serverGroup = new Group(stack, "server", {
        name: "server"
    })
    const agentGroup = new Group(stack, "agent", {
        name: "agent"
    })
    new Group(stack, "k3s_cluster", {
        children: [serverGroup.name, agentGroup.name],
        name: "k3s_cluster",
    });

    const pmNodeName = new TerraformVariable(stack, "pm_node_name", {
        type: VariableType.STRING,
    });
    const lxcDefaultGateway = new TerraformVariable(
        stack,
        "lxc_default_gateway",
        {
            default: "192.168.1.1",
            type: VariableType.STRING,
        }
    );
    const lxcIpPrefix = new TerraformVariable(stack, "lxc_ip_prefix", {
        default: "192.168.1",
        type: VariableType.STRING,
    });
    const lxcOstemplate = new TerraformVariable(stack, "lxc_ostemplate", {
        default: "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst",
        type: VariableType.STRING,
    });
    const lxcStorage = new TerraformVariable(stack, "lxc_storage", {
        default: "local-zfs",
        type: VariableType.STRING,
    });

    const serverNodes = []
    for (let i = 0; i < SERVER_NODE_COUNT; i++) {
        const serverNode = new Lxc(stack, "control_node_" + (i + 1), {
            provider,
            cores: 1,
            features: {},
            hostname:
                "lxc-control-node-" + (i + 1),
            memory: 1024,
            network: [
                {
                    bridge: "vmbr0",
                    gw: lxcDefaultGateway.stringValue,
                    ip: `${lxcIpPrefix.value}.${190 + i}/32`,
                    name: "eth0",
                },
            ],
            onboot: true,
            ostemplate: lxcOstemplate.stringValue,
            password: lxcPassword.result,
            rootfs: {
                size: "4G",
                storage: lxcStorage.stringValue,
            },
            sshPublicKeys: lxcSshKey.publicKeyOpenssh,
            start: false,
            targetNode: pmNodeName.stringValue,
            unprivileged: false,
            vmid: 2000 + i,
        });

        new Host(stack, "control_node_host_" + (i + 1), {
            groups: [serverGroup.name],
            name: serverNode.hostname,
            variables: {
                ansible_host: serverNode.network.get(0).ip,
                ansible_python_interpreter: "/usr/bin/python3",
                ansible_ssh_private_key_file: lxcSshKey.privateKeyPem,
                ansible_user: "root",
                vmid: serverNode.vmid.toString(),
            }
        })
    }

    for (let i = 0; i < AGENT_NODE_COUNT; i++) {
        const agentNode = new Lxc(stack, "work_node_" + (i + 1), {
            provider,
            cores: 2,
            features: {},
            hostname:
                "lxc-work-node-" + (i + 1),
            memory: 2048,
            network: [
                {
                    bridge: "vmbr0",
                    gw: lxcDefaultGateway.stringValue,
                    ip: `${lxcIpPrefix.value}.${190 + i + serverNodes.length}/32`,
                    name: "eth0",
                },
            ],
            onboot: true,
            ostemplate: lxcOstemplate.stringValue,
            password: lxcPassword.result,
            rootfs: {
                size: "32G",
                storage: lxcStorage.stringValue,
            },
            sshPublicKeys: lxcSshKey.publicKeyOpenssh,
            start: false,
            targetNode: pmNodeName.stringValue,
            unprivileged: false,
            vmid: 1000 + i,
        });
        new Host(stack, "work_node_host_" + (i + 1), {
            groups: [agentGroup.name],
            name: agentNode.hostname,
            variables: {
                ansible_host: agentNode.network.get(0).ip,
                ansible_python_interpreter: "/usr/bin/python3",
                ansible_ssh_private_key_file: lxcSshKey.privateKeyPem,
                ansible_user: "root",
                vmid: agentNode.vmid.toString(),
            }
        })
    }
    return {
        lxcPassword,
        lxcSshKey,
    }
}