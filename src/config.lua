local config = {}

if os.getenv("ENV") == "test" then
    config["verification-channel"] = "787593880069079071"
    config["role-verified"] = "715186122636001300"
else
    config["verification-channel"] = "787286149755568139"
    config["role-verified"] = "787027339900092447"
end

return config