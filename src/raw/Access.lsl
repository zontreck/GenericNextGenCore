#include "src/includes/common.lsl"




string g_sMasterPassword = "";
list g_lOwners;
integer g_iSelfOwned = TRUE;



integer iSetor(integer Test, integer A, integer B)
{
    if(Test)return A;
    return B;
}
ResaveOwners()
{
    llLinksetDataDeleteFound("access_owner", MASTER_CODE);
    
    
    integer i=0;
    integer end = llGetListLength(g_lOwners);
    for(i=0;i<end;i++)
    {
        llLinksetDataWriteProtected("access_owner"+(string)i, llList2String(g_lOwners, i), MASTER_CODE);
    }
}

integer g_iGroupEnabled=0;
integer g_iPublicEnabled=0;

integer calcAuthLevel(key kID)
{
    if(llGetListLength(g_lOwners))
    {
        if(~llListFindList(g_lOwners, [(string)kID])) return ACCESS_OWNER;
        if(kID == llGetOwner() && g_iSelfOwned) return ACCESS_SELF_OWN;
        else if(kID == llGetOwner() && !g_iSelfOwned) return ACCESS_WEARER;
        if(g_iGroupEnabled && llSameGroup(kID)) return ACCESS_GROUP;
        if(g_iPublicEnabled) return ACCESS_PUBLIC;

        return ACCESS_NO_ACCESS;
    }else {
        if(kID == llGetOwner())
            return ACCESS_OWNER;
        
        if(g_iGroupEnabled && llSameGroup(kID)) return ACCESS_GROUP;
        if(g_iPublicEnabled) return ACCESS_PUBLIC;

        return ACCESS_NO_ACCESS;
    }
}

default
{
    state_entry()
    {
        integer num_owners = llLinksetDataCountFound("access_owner");
        integer i=0;
        for(i=0;i<num_owners;i++)
        {
            g_lOwners += llLinksetDataReadProtected("access_owner"+(string)i, MASTER_CODE);
        }

        llListen(-9451, "", "", "");
    }

    listen(integer c,string n,key i,string m)
    {
        if(c == -9451)
        {
            if(g_sMasterPassword == "")return; // Ignore blank codes!
            if(g_sMasterPassword == m)
            {
                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "master_key_used"]), llGetOwnerKey(i));
            }
        }
    }
    
    link_message(integer s, integer n,string m,key i)
    {
        if(n == LM_SETTINGS_READY)
        {
            readSetting("access_password", "000000");
            readSetting("access_selfown", "1");
            readSetting("access_public", "0");
            readSetting("access_group", "0");


            return;
        } else if(n == 0)
        {
            if(llJsonGetValue(m,["cmd"]) == "check_code")
            {
                integer RET = 0;
                if(g_sMasterPassword == llJsonGetValue(m,["code"])){
                    RET = TRUE;
                }else RET = FALSE;
                
                llMessageLinked(LINK_SET, n, llList2Json(JSON_OBJECT, ["cmd", "check_code_back", "val", RET, "callback", llJsonGetValue(m,["callback"])]), i);
            } else if(llJsonGetValue(m,["cmd"]) == "check_mode")
            {
                llMessageLinked(LINK_SET,n,llList2Json(JSON_OBJECT, ["cmd", "check_mode_back", "val", calcAuthLevel(i), "callback", llJsonGetValue(m,["callback"])]), i);
            } else if(llJsonGetValue(m,["cmd"]) == "add_owner")
            {
                g_lOwners += llJsonGetValue(m,["id"]);
                
                llLinksetDataWriteProtected("access_owner" + (string)(llGetListLength(g_lOwners)-1), llJsonGetValue(m,["id"]), MASTER_CODE);
            } else if(llJsonGetValue(m,["cmd"]) == "rem_owner")
            {
                string sID = llJsonGetValue(m,["id"]);
                integer index=llListFindList(g_lOwners, [sID]);
                if(index == -1)
                {
                    return;
                }else{
                    g_lOwners = llDeleteSubList(g_lOwners, index,index);
                    ResaveOwners();
                }
            } else if(llJsonGetValue(m,["cmd"]) == "reset")
            {
                llResetScript();
            } else if(llJsonGetValue(m,["cmd"]) == "set_master_password")
            {
                g_sMasterPassword = llJsonGetValue(m,["pwd"]);
                llLinksetDataWriteProtected("access_password", g_sMasterPassword, MASTER_CODE);
            } else if(llJsonGetValue(m,["cmd"]) == "set_self_own")
            {
                g_iSelfOwned = (integer)llJsonGetValue(m,["val"]);
                llLinksetDataWriteProtected("access_selfown", (string)g_iSelfOwned, MASTER_CODE);
            } else if(llJsonGetValue(m,["cmd"]) == "update_group")
            {
                g_iGroupEnabled = (integer)llJsonGetValue(m,["val"]);
                llLinksetDataWriteProtected("access_group", (string)g_iGroupEnabled, MASTER_CODE);
            } else if(llJsonGetValue(m,["cmd"]) == "update_public")
            {
                g_iPublicEnabled = (integer)llJsonGetValue(m,["val"]);
                llLinksetDataWriteProtected("access_public", (string)g_iPublicEnabled, MASTER_CODE);
            } else if(llJsonGetValue(m,["cmd"]) == "read_setting_back")
            {
                string sSetting = llJsonGetValue(m,["setting"]);
                string sValue = llJsonGetValue(m,["value"]);

                switch(sSetting)
                {
                    case "access_password":
                    {
                        g_sMasterPassword = sValue;
                        break;
                    }
                    case "access_selfown":
                    {
                        g_iSelfOwned = (integer)sValue;
                        break;
                    }
                    case "access_group":
                    {
                        g_iGroupEnabled = (integer)sValue;
                        break;
                    }
                    case "access_public":
                    {
                        g_iPublicEnabled = (integer)sValue;
                        break;
                    }
                }
            }
        }
        
    }
}
