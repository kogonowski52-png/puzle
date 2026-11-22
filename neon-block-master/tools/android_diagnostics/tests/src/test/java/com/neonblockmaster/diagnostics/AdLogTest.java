package com.neonblockmaster.diagnostics;
import com.neonblockmaster.android.AdLog;
import java.io.ByteArrayInputStream;
import java.util.List;
import org.junit.Test;
import static org.junit.Assert.*;
public class AdLogTest {
    @Test public void captureIsRestrictedToTheExplicitAppProcessAndSdkTags(){
        List<String> command=AdLog.command(321);
        assertTrue(command.contains("--pid=321"));
        assertTrue(command.contains("Ads:V"));assertTrue(command.contains("*:S"));
        assertEquals("main",command.get(command.indexOf("-b")+1));
    }
    @Test public void captureIsBounded()throws Exception{
        byte[] source=new byte[30000];java.util.Arrays.fill(source,(byte)'A');
        assertEquals(16384,AdLog.readBounded(new ByteArrayInputStream(source),16384).length());
    }
    @Test public void invalidProcessIsRejected(){
        try{AdLog.command(-1);fail("invalid pid accepted");}catch(IllegalArgumentException expected){}
    }
}
