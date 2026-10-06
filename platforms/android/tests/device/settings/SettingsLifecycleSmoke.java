package app.lingyao.android.test;

import android.os.ParcelFileDescriptor;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

/** Controller lives outside the product, so normal Tauri window exit is observable. */
public final class SettingsLifecycleSmoke extends DeviceSmoke {
    @Override protected String successDescription() { return "IME process survives settings close and reopen with working input"; }
    @Override protected void runChecks() throws Exception {
        stage = "initial IME process";
        // The preceding instrumentation may force-stop its target package. Rebind
        // once before measuring; never rebind between either settings close and input.
        shell("ime disable app.lingyao.android/app.lingyao.android.LINGYAOInputService");
        shell("ime enable app.lingyao.android/app.lingyao.android.LINGYAOInputService");
        shell("ime set app.lingyao.android/app.lingyao.android.LINGYAOInputService");
        android.os.SystemClock.sleep(1000);
        shell("am start -W -f 0x10008000 -n app.lingyao.android.test/app.lingyao.android.test.EditorActivity");
        tap(field("lingyao-test-plain"));
        await(key("n"));
        String originalPid = shell("pidof app.lingyao.android:ime").trim();
        if (!originalPid.matches("[0-9]+")) throw new AssertionError("Dedicated IME process missing");
        for (int iteration = 0; iteration < 2; iteration++) {
            stage = "settings open and close";
            shell("am start -W -n app.lingyao.android/.MainActivity");
            await(node -> equalsText("app.lingyao.android", node.getPackageName()) && equalsText("android.webkit.WebView", node.getClassName()));
            shell("input keyevent 4");
            await(field("lingyao-test-plain"));
            String afterPid = shell("pidof app.lingyao.android:ime").trim();
            if (!originalPid.equals(afterPid)) throw new AssertionError("Closing settings restarted the IME process");
            stage = "input after settings close";
            tap(field("lingyao-test-plain"));
            for (String key : new String[] {"n", "i", "h", "a", "o"}) tap(key(key));
            tap(key("空格"));
            String expected = iteration == 0 ? "你好" : "你好你好";
            await(field("lingyao-test-plain").and(node -> equalsText(expected, node.getText())));
        }
    }
    private String shell(String command) throws Exception {
        try (var input = new ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)); var output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[1024];
            int count;
            while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
            return new String(output.toByteArray(), StandardCharsets.UTF_8);
        }
    }
}
