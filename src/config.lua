local config = {}

if os.getenv("ENV") == "test" then
    config["verification-channel"] = "787593880069079071"
else
    config["verification-channel"] = "787286149755568139"
end

return config