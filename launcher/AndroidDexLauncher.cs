using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class AndroidDexLauncher
{
    [STAThread]
    private static void Main()
    {
        var root = AppDomain.CurrentDomain.BaseDirectory;
        var bootstrap = Path.Combine(root, "Android_Dex", "Launcher_AQ.bat");
        var runtime = Path.Combine(root, "Android_Dex", "Android_Dex.exe");
        if (!File.Exists(bootstrap) || !File.Exists(runtime))
        {
            MessageBox.Show("A edição Aquino não encontrou Launcher_AQ.bat ou Android_Dex.exe. Reextraia o pacote completo.", "Android Dex by Aquino", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        Process.Start(new ProcessStartInfo(bootstrap)
        {
            WorkingDirectory = Path.GetDirectoryName(bootstrap),
            UseShellExecute = true,
            WindowStyle = ProcessWindowStyle.Hidden
        });
    }
}
