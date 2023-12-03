#include "src/includes/common.lsl"

string PLUGIN_NAME = "Gag";

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



call_menu(integer id, key kAv)
{

    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "check_mode", "callback", llList2Json(JSON_OBJECT, ["script", llGetScriptName(), "id", id])]), kAv);
}
integer g_iGagged;
integer g_iGagLevel;

integer g_iGagPrim;

Main(key kID, integer iAuth)
{
    list lMenu = ["main..", Checkbox(g_iGagged, "Gag"), " ", Checkbox((g_iGagLevel==0), "No Garble"), Checkbox((g_iGagLevel==1), "Loose"), Checkbox((g_iGagLevel == 2), "Medium"), Checkbox((g_iGagLevel==3), "Tight")];
    list lHelper = [];
    string sText =  "Gag Menu";


    Menu(kID, sText, lMenu, "menu~gag", SetDSMeta([iAuth]), lHelper);
}

string garble(string in) {

    string input = in;

    if(input == "." || input=="," || input == ":" || input == "?" || input ==";" || input == " " || input=="!" || input == ")" || input=="(" || input == "{" || input == "}" || input == "\\" || input == "/")input=input;
    
    if(input == "a" || input == "e" ) input="eh";
    
    if((input == "i" || input == "y") && g_iGagLevel >1)input="eh";
    
    if((input == "o" || input=="u") && g_iGagLevel > 1) input = "h";
    
    if(input == "c" || input == "k" || input=="q") input="k";
    
    if((input == "m" || input=="r") && g_iGagLevel > 1) input="w";
    
    if(input == "s" && g_iGagLevel>1) input="sh";
    
    if(input == "z")input="shh";  // or maybe silent.. 
    
    if(input == "b" || input == "p" || input == "v") input="f";
    
    if(input == "x")input = "ek";
    
    
    
    
    if(input=="shh" && g_iGagLevel==3)input="";
    
    if(input == "ek" && g_iGagLevel == 3) input="eh";

    return input;
}

string garbleString(string input)
{
    integer i=0;
    string out;
    integer len = llStringLength(input);
    for(i = 0;i<len; i++)
    {
        out += garble(llGetSubString(input,i,i));
    }

    return out;
}
integer g_iChatChannel;
integer g_iChatHandle;
integer g_iEmoteChannel;
integer g_iEmoteHandle;
UpdateGag()
{
    if(g_iGagged)
    {
        llSetLinkAlpha(g_iGagPrim, 1.0, ALL_SIDES);
    }else {
        llSetLinkAlpha(g_iGagPrim, 0.0, ALL_SIDES);

    }


    llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);

    if(g_iGagLevel > 0 && g_iGagged)
    {
        // Update Listeners
        llListenRemove(g_iChatHandle);
        llListenRemove(g_iEmoteHandle);
        g_iChatChannel = llRound(llFrand(0xFFFFF));
        g_iEmoteChannel = llRound(llFrand(0xFFFFF));

        g_iChatHandle = llListen(g_iChatChannel, "", llGetOwner(), "");
        g_iEmoteHandle = llListen(g_iEmoteChannel, "", llGetOwner(), "");

        llOwnerSay("@redirchat:" + (string)g_iChatChannel +"=add,rediremote:"+(string)g_iEmoteChannel +"=add");

    } else {
        llOwnerSay("@redirchat:" + (string)g_iChatChannel +"=rem,rediremote:"+(string)g_iEmoteChannel +"=rem");
        llOwnerSay("@clear=redirchat,clear=rediremote");
        llListenRemove(g_iChatHandle);
        llListenRemove(g_iEmoteHandle);
    }
}
default
{
    state_entry()
    {
        integer i = 0;
        integer end = llGetNumberOfPrims();

        integer iHasGag = 0;
        for(i=LINK_ROOT; i<=end;i++)
        {
            string sDesc = llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]),0);
            if(sDesc == "gag")
            {
                g_iGagPrim = i;
                iHasGag=1;
            }
        }

        if(!iHasGag)
        {
            llOwnerSay(llGetScriptName()+" has been removed because the required prim could not be found. Please ensure a prim with the description of 'gag' is present.");
        }
    }

    listen(integer c,string n,key i,string m)
    {
        string oldName = llGetObjectName();
        llSetObjectName(llGetDisplayName(llGetOwner()));
        if(c == g_iChatChannel)
        {
            llSay(0, garbleString(m));
        }else if(c == g_iEmoteChannel)
        {
            list lEmote = llParseString2List(m,["\""],[]);
            integer x = 0;
            integer e = llGetListLength(lEmote);

            for(x=0;x<e;x+=2)
            {
                lEmote = llListReplaceList(lEmote, [garbleString(llList2String(lEmote,x+1))], x+1, x+1);
            }
            llSay(0, llDumpList2String(lEmote, "\""));
        }

        llSetObjectName(oldName);
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            if(g_iGagged)
            {
                llStartAnimation("bento_open_mouth");
            }else {
                llStopAnimation("bento_open_mouth");
            }
        }
    }

    link_message(integer s,integer n,string m,key i)
    {
        if(n==0)
        {
            if(llJsonGetValue(m,["cmd"]) == "reset")
            {
                llResetScript();
            } else if(llJsonGetValue(m,["cmd"]) == "scan_plugins")
            {
                llMessageLinked(LINK_SET,0,llList2Json(JSON_OBJECT, ["cmd", "plugin_reply", "name", PLUGIN_NAME]), "");
            } else if(llJsonGetValue(m,["cmd"]) == "pass_menu")
            {
                if(llJsonGetValue(m,["plugin"]) == PLUGIN_NAME)
                    call_menu(1, i);
            } else if(llJsonGetValue(m,["cmd"]) == "check_mode_back")
            {
                
                integer access = (integer)llJsonGetValue(m,["val"]);
                
                if(access != 99){
                    string sPacket = llJsonGetValue(m,["callback"]);
                    if(llGetScriptName() == llJsonGetValue(sPacket, ["script"]))
                    {
                        integer iMenu = (integer)llJsonGetValue(sPacket, ["id"]);
                                                
                        if(iMenu == 1)
                            Main(i, access);
                    }
                }
                else llRegionSayTo(i,0,"Access Denied");
                
            }  else if(llJsonGetValue(m,["cmd"]) == "read_setting_back")
            {
                string sSetting = llJsonGetValue(m,["setting"]);
                string sValue = llJsonGetValue(m,["value"]);

                switch(sSetting)
                {
                    case "gag_gagged":
                    {
                        g_iGagged = (integer)sValue;
                        
                        
                        break;
                    }
                    case "gag_level":
                    {
                        g_iGagLevel = (integer)sValue;
                        break;
                    }
                }


                if(~llSubStringIndex(sSetting, "gag_"))
                    UpdateGag();
            }
        }else if(n == LINK_MENU_CHANNEL)
        {
            if(i == "ident")
            {
                //channel = m
            }
        }else if(n == LINK_MENU_RETURN)
        {
            if(llJsonGetValue(m, ["type"]) == "menu_back")
            {
                string sIdent = llJsonGetValue(m,["id"]);
                key kAv = i;
                string sReply = llJsonGetValue(m,["reply"]);
                string sExtra = llJsonGetValue(m,["extra"]);
                list lExtra = llParseString2List(sExtra, [":"],[]);

                integer iAuth = (integer)llList2String(lExtra,0);


                integer iRespring=1;
                integer iMenu;

                if(sReply == "-exit-")
                {
                    return;
                }
                switch(sIdent)
                {
                    case "menu~gag":
                    {
                        iMenu = 1;
                        switch(sReply)
                        {
                            case "main..":
                            {
                                iRespring=0;
                                llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "pass_menu", "plugin", "Main"]), kAv);
                                break;
                            }
                            case Checkbox(g_iGagged, "Gag"):
                            {
                                writeSetting("gag_gagged", (string)(!g_iGagged));
                                break;
                            }
                            default :
                            {
                                string label = Uncheckbox(sReply);
                                switch(label)
                                {
                                    case "No Garble":
                                    {
                                        g_iGagLevel = 0;
                                        break;
                                    }
                                    case "Loose":{
                                        g_iGagLevel = 1;
                                        break;
                                    }
                                    case "Medium": {
                                        g_iGagLevel = 2;
                                        break;
                                    }
                                    case "Tight":{
                                        g_iGagLevel = 3;
                                        break;
                                    }
                                }

                                llLinksetDataWriteProtected("gag_level", (string)g_iGagLevel, MASTER_CODE);
                            }
                        }
                        break;
                    }
                }

                if(iRespring)
                {
                    call_menu(iMenu, kAv);
                }
            }
        } else if(n == LM_SETTINGS_READY)
        {
            // Load Settings Here
            readSetting("gag_gagged", "0");
            readSetting("gag_level", "0");
        }
    }
}