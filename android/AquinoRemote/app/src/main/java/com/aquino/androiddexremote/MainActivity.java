package com.aquino.androiddexremote;

import android.app.*;
import android.os.*;
import android.content.*;
import android.graphics.Color;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import org.json.JSONObject;

public class MainActivity extends Activity {
    private EditText host, token;
    private TextView status;
    private LinearLayout root, actions;

    private int dp(int v) { return (int)(v * getResources().getDisplayMetrics().density + .5f); }

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setStatusBarColor(Color.rgb(16,19,24));
        buildUi();
        loadPrefs();
        refreshStatus();
    }

    private TextView text(String s, int size, boolean bold) {
        TextView v = new TextView(this); v.setText(s); v.setTextColor(Color.WHITE); v.setTextSize(size);
        if (bold) v.setTypeface(null, android.graphics.Typeface.BOLD);
        return v;
    }

    private void buildUi() {
        ScrollView sc = new ScrollView(this); sc.setBackgroundColor(Color.rgb(16,19,24));
        root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setPadding(dp(18),dp(18),dp(18),dp(30));
        sc.addView(root); setContentView(sc);
        root.addView(text("Aquino Remote", 28, true));
        TextView sub = text("Controle remoto do Android Dex by Aquino", 15, false); sub.setTextColor(Color.LTGRAY); root.addView(sub);
        TextView dev = text("Desenvolvedor: Aquino1M  •  Aquino1M/SamsungDexbyAquino", 13, false); dev.setPadding(0,dp(6),0,dp(16)); dev.setTextColor(Color.rgb(130,170,255));
        dev.setOnClickListener(v -> startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/Aquino1M/SamsungDexbyAquino")))); root.addView(dev);

        host = new EditText(this); host.setHint("IP do PC (ex.: 192.168.1.10)"); host.setTextColor(Color.WHITE); host.setHintTextColor(Color.GRAY); host.setSingleLine(true); root.addView(host);
        token = new EditText(this); token.setHint("Código/token do launcher"); token.setTextColor(Color.WHITE); token.setHintTextColor(Color.GRAY); token.setSingleLine(true); root.addView(token);
        Button save = button("Salvar conexão", "save"); root.addView(save);
        status = text("Status: não conectado", 15, true); status.setPadding(0,dp(14),0,dp(12)); root.addView(status);
        actions = new LinearLayout(this); actions.setOrientation(LinearLayout.VERTICAL); root.addView(actions);

        addAction("▶ Iniciar / focar Android Dex", "focus");
        addAction("🎮 Gaming Hub", "gaming_hub");
        addAction("🕹 Editor de Gamepad", "gamepad_editor");
        addAction("⌨ KeyMapper", "keymapper");
        addAction("⛶ Tela cheia", "fullscreen");
        addAction("🔄 Reparar ADB", "repair_adb");
        addAction("📶 Conexão Wi‑Fi / ADB", "wireless_adb");
        addAction("📊 Diagnóstico", "diagnostics");
        addAction("🛑 Fechar Android Dex", "close_dex");

        TextView feat = text("Recursos 0.5.0", 20, true); feat.setPadding(0,dp(22),0,dp(8)); root.addView(feat);
        TextView info = text("• Controle do launcher pela rede local\n• Acesso rápido ao Gaming Hub, Gamepad e KeyMapper\n• Tela cheia, reparo ADB e diagnóstico\n• Estado do Android Dex/ADB em tempo real\n• Integração oficial da edição Aquino1M", 14, false); info.setTextColor(Color.LTGRAY); root.addView(info);
    }

    private Button button(String label, String action) {
        Button b = new Button(this); b.setText(label); b.setAllCaps(false); b.setTextSize(15); b.setMinHeight(dp(50));
        b.setOnClickListener(v -> { if (action.equals("save")) { savePrefs(); refreshStatus(); } else send(action); }); return b;
    }
    private void addAction(String label, String action) { Button b = button(label,action); LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1,-2); p.setMargins(0,dp(5),0,dp(5)); actions.addView(b,p); }
    private String base() { return "http://" + host.getText().toString().trim() + ":37891"; }
    private void savePrefs() { getSharedPreferences("aq",0).edit().putString("host",host.getText().toString().trim()).putString("token",token.getText().toString().trim()).apply(); Toast.makeText(this,"Conexão salva",Toast.LENGTH_SHORT).show(); }
    private void loadPrefs() { android.content.SharedPreferences p=getSharedPreferences("aq",0); host.setText(p.getString("host","")); token.setText(p.getString("token","")); }

    private String request(String path, String method, String body) throws Exception {
        HttpURLConnection c=(HttpURLConnection)new URL(base()+path).openConnection(); c.setConnectTimeout(2500); c.setReadTimeout(4500); c.setRequestMethod(method); c.setRequestProperty("X-Aquino-Token",token.getText().toString().trim());
        if(body!=null){c.setDoOutput(true);c.setRequestProperty("Content-Type","application/json");try(OutputStream o=c.getOutputStream()){o.write(body.getBytes(StandardCharsets.UTF_8));}}
        int code=c.getResponseCode(); InputStream in=(code>=200&&code<300)?c.getInputStream():c.getErrorStream(); if(in==null)throw new IOException("HTTP "+code); ByteArrayOutputStream out=new ByteArrayOutputStream(); byte[]buf=new byte[4096];int n;while((n=in.read(buf))>0)out.write(buf,0,n); if(code<200||code>=300)throw new IOException("HTTP "+code+": "+out); return out.toString("UTF-8");
    }
    private void refreshStatus(){ new Thread(()->{ try { String s=request("/status","GET",null); JSONObject j=new JSONObject(s); runOnUiThread(()->status.setText("Status: "+(j.optBoolean("dexRunning")?"Dex online":"Dex parado")+" • ADB "+(j.optBoolean("adbOnline")?"OK":"offline"))); } catch(Exception e){runOnUiThread(()->status.setText("Status: sem conexão com o PC"));} }).start(); }
    private void send(String action){ new Thread(()->{ try { JSONObject j=new JSONObject();j.put("action",action); request("/action","POST",j.toString()); runOnUiThread(()->Toast.makeText(this,"Comando enviado: "+action,Toast.LENGTH_SHORT).show()); try{Thread.sleep(500);}catch(Exception ignored){} refreshStatus(); } catch(Exception e){runOnUiThread(()->Toast.makeText(this,"Falha: "+e.getMessage(),Toast.LENGTH_LONG).show());} }).start(); }
}
