#include "src/includes/common.lsl"




string sSetor(integer test, string a, string b)
{
    if(test)return a;
    return b;
}

default
{
    state_entry()
    {
        llMessageLinked(LINK_SET, 10, "", "");
    }

    changed(integer c)
    {
        if(c&CHANGED_INVENTORY)
        {
            llSleep(2);
            llMessageLinked(LINK_SET, 10, "", "");
        }
    }

    link_message(integer s,integer n,string m,key i)
    {
        if(n == 0)
        {
            if(llJsonGetValue(m,["cmd"]) == "reset")
            {
                llResetScript();
            } else if(llJsonGetValue(m,["cmd"]) == "write_setting")
            {
                llLinksetDataWriteProtected(llJsonGetValue(m,["name"]), llJsonGetValue(m,["value"]), MASTER_CODE);

                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "read_setting_back", "setting", llJsonGetValue(m,["name"]), "value", llJsonGetValue(m,["value"])]), "");
            } else if(llJsonGetValue(m,["cmd"]) == "read_setting")
            {
                string reply = llLinksetDataReadProtected(llJsonGetValue(m,["name"]), MASTER_CODE);

                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "read_setting_back", "setting", llJsonGetValue(m,["name"]), "value", sSetor((reply==""), llJsonGetValue(m,["default"]), reply)]), "");
            } else if(llJsonGetValue(m,["cmd"]) == "delete_setting")
            {
                llLinksetDataDeleteProtected(llJsonGetValue(m,["name"]), MASTER_CODE);
                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "read_setting_back", "setting", llJsonGetValue(m,["name"]), "value", llJsonGetValue(m,["default"])]), "");
            }
        } else if(n == 11)
        {
            llMessageLinked(LINK_SET, 10, "", "");
        }
    }
}