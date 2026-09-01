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
        var executable = Path.Combine(root, "Android_Dex", "Android_Dex.exe");
        if (!File.Exists(executable))
        {
            MessageBox.Show("Android_Dex.exe nao foi encontrado na pasta Android_Dex.", "Android Dex by Aquino", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        Process.Start(new ProcessStartInfo(executable) { WorkingDirectory = Path.GetDirectoryName(executable), UseShellExecute = true });
    }
}
