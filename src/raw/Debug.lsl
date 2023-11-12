default
{
    state_entry()
    {

    }

    link_message(integer s,integer n,string m,key i)
    {
        llSay(0, llDumpList2String([n,m,i], " ~ "));
    }
}