package com.aquino.androiddexremote;

import android.app.*;
import android.os.*;
import android.content.*;
import android.graphics.Color;
import android.net.Uri;
import android.text.InputType;
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
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable statusLoop = new Runnable() { public void run() { refreshStatus(); handler.postDelayed(this, 5000); } };

    private int dp(int v) { return (int)(v * getResources().getDisplayMetrics().density + .5f); }

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setStatusBarColor(Color.rgb(16,19,24));
        buildUi(); loadPrefs(); refreshStatus();
    }
    @Override protected void onResume() { super.onResume(); handler.removeCallbacks(statusLoop); handler.postDelayed(statusLoop, 5000); }
    @Override protected void onPause() { handler.removeCallbacks(statusLoop); super.onPause(); }

    private TextView text(String s, int size, boolean bold) {
        TextView v = new TextView(this); v.setText(s); v.setTextColor(Color.WHITE); v.setTextSize(size);
        if (bold) v.setTypeface(null, android.graphics.Typeface.BOLD); return v;
    }
    private LinearLayout row() { LinearLayout r=new LinearLayout(this); r.setOrientation(LinearLayout.HORIZONTAL); r.setWeightSum(2f); return r; }
    private void addHalf(LinearLayout row, String label, String action) { Button b=button(label,action); LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,-2,1f); p.setMargins(dp(3),dp(4),dp(3),dp(4)); row.addView(b,p); }

    private void buildUi() {
        ScrollView sc = new ScrollView(this); sc.setBackgroundColor(Color.rgb(16,19,24));
        root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setPadding(dp(18),dp(18),dp(18),dp(30));
        sc.addView(root); setContentView(sc);
        root.addView(text("Aquino Remote", 28, true));
        TextView sub = text("Controle remoto do Android Dex by Aquino", 15, false); sub.setTextColor(Color.LTGRAY); root.addView(sub);
        TextView dev = text("Desenvolvedor: Aquino1M  •  Aquino1M/SamsungDexbyAquino", 13, false); dev.setPadding(0,dp(6),0,dp(16)); dev.setTextColor(Color.rgb(130,170,255));
        dev.setOnClickListener(v -> startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/Aquino1M/SamsungDexbyAquino")))); root.addView(dev);

        host = new EditText(this); host.setHint("IP do PC (ex.: 192.168.1.10)"); host.setTextColor(Color.WHITE); host.setHintTextColor(Color.GRAY); host.setSingleLine(true); root.addView(host);
        token = new EditText(this); token.setHint("Código/token do launcher"); token.setTextColor(Color.WHITE); token.setHintTextColor(Color.GRAY); token.setSingleLine(true); token.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD); root.addView(token);
        LinearLayout conn=row(); addHalf(conn,"Salvar conexão","save"); addHalf(conn,"Atualizar status","refresh"); root.addView(conn);
        status = text("Status: não conectado", 15, true); status.setPadding(0,dp(14),0,dp(12)); root.addView(status);
        actions = new LinearLayout(this); actions.setOrientation(LinearLayout.VERTICAL); root.addView(actions);

        addAction("▶ Iniciar / focar Android Dex", "focus");
        LinearLayout gaming=row(); addHalf(gaming,"🎮 Gaming Hub","gaming_hub"); addHalf(gaming,"🪟 Abrir jogo","game_launcher"); actions.addView(gaming);
        LinearLayout editors=row(); addHalf(editors,"🕹 Gamepad","gamepad_editor"); addHalf(editors,"⌨ KeyMapper","keymapper"); actions.addView(editors);

        TextView device = text("Controles do Android", 18, true); device.setPadding(0,dp(16),0,dp(5)); actions.addView(device);
        LinearLayout nav=row(); addHalf(nav,"← Voltar","back"); addHalf(nav,"⌂ Home","home"); actions.addView(nav);
        LinearLayout nav2=row(); addHalf(nav2,"▣ Recentes","recents"); addHalf(nav2,"↻ Girar 90°","rotate"); actions.addView(nav2);
        LinearLayout orient=row(); addHalf(orient,"▭ Horizontal","landscape"); addHalf(orient,"▯ Vertical","portrait"); actions.addView(orient);
        LinearLayout vol=row(); addHalf(vol,"🔉 Volume −","volume_down"); addHalf(vol,"🔊 Volume +","volume_up"); actions.addView(vol);

        addAction("⛶ Tela cheia do Dex", "fullscreen");
        LinearLayout tools=row(); addHalf(tools,"🔄 Reparar ADB","repair_adb"); addHalf(tools,"📶 Wi‑Fi / ADB","wireless_adb"); actions.addView(tools);
        addAction("📊 Diagnóstico", "diagnostics");
        addAction("🛑 Fechar Android Dex", "close_dex");

        TextView feat = text("Recursos 0.7.1 Audited", 20, true); feat.setPadding(0,dp(22),0,dp(8)); root.addView(feat);
        TextView info = text("• Controle do launcher pela rede local com token seguro\n• Gaming Hub, janela de jogo, Gamepad e KeyMapper\n• Voltar, Home, Recentes, horizontal/vertical, rotação e volume pelo celular\n• Tela cheia, reparo ADB, Wireless ADB e diagnóstico\n• Status automático do Dex/ADB a cada 5 segundos", 14, false); info.setTextColor(Color.LTGRAY); root.addView(info);
    }

    private Button button(String label, String action) {
        Button b = new Button(this); b.setText(label); b.setAllCaps(false); b.setTextSize(14); b.setMinHeight(dp(50));
        b.setOnClickListener(v -> { if (action.equals("save")) { savePrefs(); refreshStatus(); } else if(action.equals("refresh")) { refreshStatus(); } else send(action); }); return b;
    }
    private void addAction(String label, String action) { Button b = button(label,action); LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1,-2); p.setMargins(0,dp(4),0,dp(4)); actions.addView(b,p); }
    private String base() { return "http://" + host.getText().toString().trim() + ":37891"; }
    private void savePrefs() { getSharedPreferences("aq",0).edit().putString("host",host.getText().toString().trim()).putString("token",token.getText().toString().trim()).apply(); Toast.makeText(this,"Conexão salva",Toast.LENGTH_SHORT).show(); }
    private void loadPrefs() { android.content.SharedPreferences p=getSharedPreferences("aq",0); host.setText(p.getString("host","")); token.setText(p.getString("token","")); }

    private String request(String path, String method, String body) throws Exception {
        if(host.getText().toString().trim().isEmpty() || token.getText().toString().trim().isEmpty()) throw new IOException("Informe IP e token do PC");
        HttpURLConnection c=(HttpURLConnection)new URL(base()+path).openConnection(); c.setConnectTimeout(2500); c.setReadTimeout(5000); c.setRequestMethod(method); c.setRequestProperty("X-Aquino-Token",token.getText().toString().trim()); c.setUseCaches(false);
        if(body!=null){c.setDoOutput(true);c.setRequestProperty("Content-Type","application/json; charset=utf-8");try(OutputStream o=c.getOutputStream()){o.write(body.getBytes(StandardCharsets.UTF_8));}}
        int code=c.getResponseCode(); InputStream in=(code>=200&&code<300)?c.getInputStream():c.getErrorStream(); if(in==null)throw new IOException("HTTP "+code); ByteArrayOutputStream out=new ByteArrayOutputStream(); byte[]buf=new byte[4096];int n;try(InputStream src=in){while((n=src.read(buf))>0)out.write(buf,0,n);} if(code<200||code>=300)throw new IOException("HTTP "+code+": "+out.toString("UTF-8")); return out.toString("UTF-8");
    }
    private void refreshStatus(){ new Thread(()->{ try { String s=request("/status","GET",null); JSONObject j=new JSONObject(s); String msg="Status: "+(j.optBoolean("dexRunning")?"Dex online":"Dex parado")+" • ADB "+(j.optBoolean("adbOnline")?"OK":"offline")+" • Android(s) "+j.optInt("devices",0)+" • bridge "+j.optString("version","?"); runOnUiThread(()->status.setText(msg)); } catch(Exception e){runOnUiThread(()->status.setText("Status: sem conexão com o PC"));} }).start(); }
    private void send(String action){ new Thread(()->{ try { JSONObject j=new JSONObject();j.put("action",action); request("/action","POST",j.toString()); runOnUiThread(()->Toast.makeText(this,"Comando enviado",Toast.LENGTH_SHORT).show()); try{Thread.sleep(350);}catch(Exception ignored){} refreshStatus(); } catch(Exception e){runOnUiThread(()->Toast.makeText(this,"Falha: "+e.getMessage(),Toast.LENGTH_LONG).show());} }).start(); }
}
