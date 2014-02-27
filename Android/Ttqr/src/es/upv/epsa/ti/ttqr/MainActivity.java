package es.upv.epsa.ti.ttqr;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class MainActivity extends Activity implements OnClickListener {
	
	private static final String TAG = MainActivity.class.getSimpleName();
	
	Button bt_texto;
	Button bt_qr;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		
		setupUI();
	}
	
	private void setupUI() {
		bt_texto = (Button)findViewById(R.id.bt_main_texto);
		bt_qr = (Button)findViewById(R.id.bt_main_qr);
		
		bt_texto.setOnClickListener(this);
		bt_qr.setOnClickListener(this);
		
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}

	@Override
	public void onClick(View v) {
		
		if(v.equals(bt_texto)) {
			Intent i = new Intent(this, VideoActivity.class);
			startActivity(i);
		} else if(v.equals(bt_qr)){

		}
		
	}

}
