#include "src/includes/common.lsl"



// Link Commands
integer     LINK_MENU_DISPLAY = 300;
integer     LINK_MENU_CLOSE = 310; 
integer     LINK_MENU_RETURN = 320;
integer     LINK_MENU_TIMEOUT = 330;
integer     LINK_MENU_CHANNEL = 303; // Returns from the dialog module to inform what the channel is
integer     LINK_MENU_ONLYCHANNEL = 302; // Sent with a ident to make a channel. No dialog will pop up, and it will expire just like any other menu if input is not received. 




string BACK = "<<";
string FORWARD = ">>";
list MENU_NAVIGATE_BUTTONS = [" ", " ", "-exit-"];

Menu(key kAv, string sText, list lButtons, string sIdent, string sExtra, list lCompanionText)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, llDumpList2String(lButtons, "~"), "", sExtra, "", llDumpList2String(lCompanionText, "~"), BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

MenuNoUtility(key kAv, string sText, list lButtons, string sIdent, string sExtra, list lCompanionText)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, llDumpList2String(lButtons, "~"), "", sExtra, "NOUTIL", llDumpList2String(lCompanionText, "~"), BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

GetArbitraryData(key kAv, string sText, string sIdent, string sExtra){
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "FALSE", sText, "", "", sExtra, "", "", BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

GetListenerChannel(string sIdent)
{
    llMessageLinked(LINK_THIS, LINK_MENU_ONLYCHANNEL, sIdent, sIdent);
}

NumberPad(key kAv, string sText, string sIdent, string sExtra)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, "numpadplz", "", sExtra, "NOUTIL", "", BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

integer g_iLocked=  FALSE;

Main(key kID, integer level)
{
    list lMenu = ["Access", "Help..", Checkbox(g_iLocked, "Locked")] + g_lPlugins;
    list lMenuHelper = ["Set or remove owners", "Core help"];
    string sText = "Welcome!\nYour Access Level is: " + ToLevelString(level)+"\n\n";

    Menu(kID, sText, lMenu, "menu~Main", SetDSMeta([level]), lMenuHelper);
}

string g_sVersion = "1.0.111123.1753";

HelpMenu(key kID, integer level)
{
    list lMenu = ["main..", "Restart"];
    list lMenuHelper = ["Go back to the main menu", "Resets and restarts all scripts"];
    string sText = "DHB Replacement Scripts\nHelp\n\nVersion: " + g_sVersion+"\n\nFree Memory: "+(string)llGetFreeMemory()+"\n\n";

    Menu(kID, sText, lMenu, "menu~help", SetDSMeta([level]), lMenuHelper);
}

AccessMenu(key kID, integer level)
{
    integer iSelfOwned = (integer)llLinksetDataReadProtected("access_selfown", MASTER_CODE);
    integer iGroup = (integer)llLinksetDataReadProtected("access_group", MASTER_CODE);
    integer iPublic = (integer)llLinksetDataReadProtected("access_public", MASTER_CODE);

    list lMenu = ["main..", "Set Passwd", "Add Owner", "Rem Owner", "List Owners", Checkbox(iSelfOwned, "SelfOwn"), Checkbox(iGroup, "Group"), Checkbox(iPublic, "Public"), "Get MasterKey"];
    list lHelper = ["Returns to the main menu", "Set the master key password", "Add a new owner", "Remove a existing owner", "List owners", "Toggle self owned status"];
    string sText = "Access Settings Menu\nCurrent Master Password: " + llLinksetDataReadProtected("access_password", MASTER_CODE) + "\n\n";


    Menu(kID, sText, lMenu, "menu~Access", SetDSMeta([level]), lHelper);
}

RemoveOwnerMenu(key kID, integer level)
{
    list lMenu = ["cancel"];
    string sText = "Who do you want to remove? \n\n";

    integer ix=0;
    integer endx = llLinksetDataCountFound("access_owner");
    for(ix=0;ix<endx;ix++)
    {
        lMenu += [llLinksetDataReadProtected("access_owner"+(string)ix, MASTER_CODE)];
    }

    Menu(kID, sText, lMenu, "menu~remowner", SetDSMeta([level]), []);
}

call_menu(integer id, key kAv)
{

    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "check_mode", "callback", llList2Json(JSON_OBJECT, ["script", llGetScriptName(), "id", id])]), kAv);
}

list g_lPlugins = [];
key g_kLockedBy = NULL_KEY;
integer g_iLockedAuth = 0;

updateRLV()
{
    if(g_iLocked)
    {
        llOwnerSay("@detach=n");
    } else {
        llOwnerSay("@detach=y");
    }
}
default
{
    state_entry()
    {
        llSetTimerEvent(10);

        updateRLV();
    }
    timer()
    {
        llSetTimerEvent(0);

        llMessageLinked(LINK_SET,0,llList2Json(JSON_OBJECT, ["cmd", "scan_plugins"]), "");
    }
    touch_start(integer t)
    {
        call_menu(1, llDetectedKey(0));
    }

    changed(integer c)
    {
        if(c&CHANGED_INVENTORY)
        {
            g_lPlugins=[];
            llSetTimerEvent(5);
        }
    }

    dataserver(key kID, string sData)
    {
        if(HasDSRequest(kID) != -1)
        {
            list lMeta = GetMetaList(kID);
            DeleteDSReq(kID);

            if(llList2String(lMeta,0) == "decodeAvatar")
            {
                if(sData != (string)NULL_KEY)
                {
                    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "add_owner", "id", sData]), "");
                    llRegionSayTo(llList2String(lMeta,2), 0, "Owner Added: " + SLURL(sData));
                    call_menu(2, llList2String(lMeta,2));
                } else {
                    llRegionSayTo(llList2String(lMeta,2), 0, "Input invalid, avatar was not found. Try again");
                    call_menu(4, llList2String(lMeta,2));
                }
            }
        }
    }

    link_message(integer s,integer n,string m,key i)
    {
        if(n == LINK_MENU_CHANNEL)
        {
            if(i == "ident")
            {
                //channel = m
            }
        } else if(n == LM_SETTINGS_READY)
        {
            readSetting("locked", "");
        }else if(n == LINK_MENU_RETURN)
        {
            if(llJsonGetValue(m, ["type"]) == "menu_back")
            {
                string sIdent = llJsonGetValue(m,["id"]);
                key kAv = i;
                string sReply = llJsonGetValue(m,["reply"]);
                string sExtra = llJsonGetValue(m,["extra"]);
                list lExtra = llParseStringKeepNulls(sExtra, [":"], []);

                integer level = (integer)llList2String(lExtra,0); // Auth Level

                integer iRespring = 1;
                integer iMenu = 0;

                integer iSelfOwned = (integer)llLinksetDataReadProtected("access_selfown", MASTER_CODE);
                integer iGroup = (integer)llLinksetDataReadProtected("access_group", MASTER_CODE);
                integer iPublic = (integer)llLinksetDataReadProtected("access_public", MASTER_CODE);

                if(sReply == "-exit-")
                {
                    return;
                }

                switch(sIdent)
                {
                    case "menu~Main":
                    {
                        iMenu = 1;
                        switch(sReply)
                        {
                            case "Access":
                            {
                                if(level <= ACCESS_WEARER)
                                {
                                    iMenu = 2;
                                }
                                break;
                            }
                            case "Help..":
                            {
                                if(level <= ACCESS_WEARER)
                                {
                                    iMenu = 6;
                                }
                                break;
                            }
                            case Checkbox(g_iLocked, "Locked"):
                            {
                                if(g_iLockedAuth >= level || !g_iLocked)
                                {

                                    g_iLocked=!g_iLocked;
                                    g_iLockedAuth = level;
                                    g_kLockedBy = kAv;

                                    updateRLV();
                                    llLinksetDataWriteProtected("locked", llList2Json(JSON_OBJECT, ["by", kAv, "level", level]), MASTER_CODE);
                                }else {
                                    llRegionSayTo(kAv, 0, "You lack the necessary permissions to unlock. Your level is " + ToLevelString(level) +"; and the locker's authority level is: "+ ToLevelString(g_iLockedAuth));
                                }
                                break;
                            }
                            default:
                            {
                                iRespring=0;
                                llMessageLinked(LINK_SET,0,llList2Json(JSON_OBJECT, ["cmd", "pass_menu", "plugin", sReply, "ray_id", llGenerateKey(), "from", iMenu]), kAv);
                                break;
                            }
                        }
                        break;
                    }
                    case "menu~Access":
                    {
                        iMenu=2;
                        switch(sReply)
                        {
                            case "main..":
                            {
                                iMenu=1;
                                break;
                            }
                            case "Set Passwd":
                            {
                                iMenu=3;
                                break;
                            }
                            case "Add Owner":
                            {
                                iMenu = 4;
                                break;
                            }
                            case "List Owners":
                            {
                                integer ix=0;
                                integer endx = llLinksetDataCountFound("access_owner");
                                llRegionSayTo(kAv, 0, "Owner X. " + SLURL(llGetOwner()));
                                for(ix=0;ix<endx;ix++)
                                {
                                    llRegionSayTo(kAv, 0, "Owner "+(string)ix+". " + SLURL(llLinksetDataReadProtected("access_owner"+(string)ix, MASTER_CODE)));
                                }
                                break;
                            }
                            case "Rem Owner":
                            {
                                iMenu=5;
                                break;
                            }
                            case Checkbox(iSelfOwned, "SelfOwn"):
                            {
                                iSelfOwned = !iSelfOwned;
                                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "set_self_own", "val", iSelfOwned]), kAv);
                                break;
                            }
                            case Checkbox(iGroup, "Group"):
                            {
                                iGroup = !iGroup;
                                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "update_group", "val", iGroup]), kAv);
                                break;
                            }
                            case Checkbox(iPublic, "Public"):
                            {
                                iPublic = !iPublic;
                                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "update_public", "val", iPublic]), kAv);
                                break;
                            }
                            case "Get MasterKey":
                            {
                                llGiveInventory(kAv, "Master Key");
                                break;
                            }
                        }
                        break;
                    }
                    case "menu~help":
                    {
                        iMenu=6;
                        switch(sReply)
                        {
                            case "main..":
                            {
                                iMenu=1;
                                break;
                            }
                            case "Restart":
                            {
                                iRespring=0;
                                llMessageLinked(LINK_SET,0, llList2Json(JSON_OBJECT, ["cmd", "reset"]), "");
                                break;
                            }
                        }
                        break;
                    }
                    case "access~passwd":
                    {
                        iMenu = 2;
                        if(sReply != "-1") // Cancel
                        {
                            llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "set_master_password", "pwd", sReply]), kAv);
                        }
                        break;
                    }
                    case "access~addowner":
                    {
                        iRespring=0;
                        key kDecode = decodeAvatarInput(sReply, kAv);
                        if(kDecode != NULL_KEY)
                        {
                            iRespring=1;
                            iMenu = 2;
                            llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "add_owner", "id", kDecode]), kAv);
                            llRegionSayTo(kAv, 0, "Owner Added: " + SLURL(sReply));
                        }
                        break;
                    }
                    case "menu~remowner":
                    {
                        iMenu=2;
                        llMessageLinked(LINK_SET ,0, llList2Json(JSON_OBJECT, ["cmd", "rem_owner", "id", sReply]), "");

                        llRegionSayTo(kAv, 0, "Owner Removed: " + SLURL(sReply));
                        break;
                    }
                }


                if(iRespring){
                    call_menu(iMenu, kAv);
                }
            }
        } else {
            if(llJsonGetValue(m,["cmd"]) == "check_mode_back")
            {
                integer access = (integer)llJsonGetValue(m,["val"]);
                
                if(access != 99){
                    string sPacket = llJsonGetValue(m,["callback"]);
                    if(llGetScriptName() == llJsonGetValue(sPacket, ["script"]))
                    {
                        integer iMenu = (integer)llJsonGetValue(sPacket, ["id"]);
                                                
                        if(iMenu == 1)
                            Main(i, access);
                        if(iMenu == 2)
                            AccessMenu(i, access);
                        if(iMenu == 3)
                            NumberPad(i, "What should the new master password be?\n\nCurrent Value: " + llLinksetDataReadProtected("access_password", MASTER_CODE), "access~passwd", SetDSMeta([access]));
                        if(iMenu == 4)
                            GetArbitraryData(i, "Who do you want to add as owner?\n\nAccepts: SLURL, UUID, Legacy Name", "access~addowner", SetDSMeta([access]));
                        if(iMenu == 5)
                            RemoveOwnerMenu(i, access);
                        if(iMenu == 6)
                            HelpMenu(i, access);
                    }
                }
                else llRegionSayTo(i,0,"Access Denied");
                
            } else if(llJsonGetValue(m,["cmd"]) == "reset")
            {
                llResetScript();
            } else if(llJsonGetValue(m,["cmd"]) == "plugin_reply")
            {
                g_lPlugins += [llJsonGetValue(m,["name"])];
            } else if(llJsonGetValue(m, ["cmd"]) == "pass_menu")
            {
                if(llJsonGetValue(m,["plugin"]) == "Main")
                {
                    call_menu(1, i);
                }
            } else if(llJsonGetValue(m,["cmd"]) == "read_setitng_back")
            {
                string sSetting = llJsonGetValue(m,["setting"]);
                string sValue = llJsonGetValue(m,["value"]);
                

                switch(sSetting)
                {
                    case "locked":
                    {
                        if(sValue == "")
                        {
                            llOwnerSay("@detach=y");
                            g_iLocked=0;
                        }else {
                            g_iLocked=1;
                            g_iLockedAuth = (integer)llJsonGetValue(sValue, ["level"]);
                            g_kLockedBy = llJsonGetValue(sValue, ["by"]);
                        }
                        break;
                    }
                }
            }
        }
    }
}
