import { TerraformVariable, VariableType } from "cdktf";
import { Construct } from "constructs";

export const defineVariables = (stack: Construct) => {


    const pmApiTokenName = new TerraformVariable(stack, "pm_api_token_name", {
        default: "terraform",
        type: VariableType.STRING,
    });
    const pmApiTokenSecret = new TerraformVariable(
        stack,
        "pm_api_token_secret",
        {
            sensitive: true,
            type: VariableType.STRING,
        }
    );
    const pmApiUser = new TerraformVariable(stack, "pm_api_user", {
        default: "terraform@pam",
        type: VariableType.STRING,
    });
    const pmHost = new TerraformVariable(stack, "pm_host", {
        default: "192.168.1.101",
        type: VariableType.STRING,
    });

    const pmPassword = new TerraformVariable(stack, "pm_password", {
        sensitive: true,
        type: VariableType.STRING,
    });
    const pmUser = new TerraformVariable(stack, "pm_user", {
        default: "root",
        type: VariableType.STRING,
    });

    return {
        pmApiTokenName,
        pmApiTokenSecret,
        pmApiUser,
        pmHost,
        pmPassword,
        pmUser,
    }
}