package es.upv.epsa.ti.ttqr;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.ColorMatrix;
import android.graphics.ColorMatrixColorFilter;
import android.graphics.Paint;

public class ImageToBlackWhite {
	
	private static Bitmap toGrayscale(Bitmap bmpOriginal)
	{        
	    int width, height;
	    height = bmpOriginal.getHeight();
	    width = bmpOriginal.getWidth();

	    Bitmap bmpGrayscale = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
	    Canvas c = new Canvas(bmpGrayscale);
	    Paint p = new Paint();
	    ColorMatrix cm = new ColorMatrix();
	    cm.setSaturation(0);
	    ColorMatrixColorFilter f = new ColorMatrixColorFilter(cm);
	    p.setColorFilter(f);
	    c.drawBitmap(bmpOriginal, 0, 0, p);
	    
	    return bmpGrayscale;
	}
	
	public Bitmap changeBitmapContrastBrightness(Bitmap bmp, float contrast, float brightness)
	{
		
	    ColorMatrix cm = new ColorMatrix(new float[]
	            {
	                contrast, 0, 0, 0, brightness,
	                0, contrast, 0, 0, brightness,
	                0, 0, contrast, 0, brightness,
	                0, 0, 0, 1, 0
	            });

	    Bitmap ret = Bitmap.createBitmap(bmp.getWidth(), bmp.getHeight(), bmp.getConfig());
	    
	    Canvas canvas = new Canvas(ret);

	    Paint pt = new Paint();
	    pt.setColorFilter(new ColorMatrixColorFilter(cm));
	    canvas.drawBitmap(toGrayscale(bmp), 0, 0, pt);

	    return ret;
	}
	
}
