package es.upv.epsa.ti.textimagedetector;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;

import es.upv.epsa.ti.textimagedetector.ImageToBlackWhite;
import es.upv.epsa.ti.textimagedetector.TextCleaner;
import es.upv.epsa.ti.textimagedetector.TextRegionDetector;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.view.SurfaceView;
import android.widget.FrameLayout;

public class VideoActivity extends Activity implements Camera.PreviewCallback {
	private Camera mCamera;
    private CameraPreview mPreview;
    private Visualization mDraw;

    private TextRegionDetector TRD = new TextRegionDetector();
	private TextCleaner TC = new TextCleaner();
	private ImageToBlackWhite ITBW = new ImageToBlackWhite();
    
	private static final int SCALE_FACTOR = 10;
	// Android image data used for displaying the results
	private Bitmap bmp;
	private Bitmap auxBmp;
	private Bitmap highContrastImage;
	private Bitmap edgeImg;
	
	private List<Rect> rects = new ArrayList<Rect>();
	private Paint rectPaint = new Paint();
		
    // Thread where image data is processed
 	private ThreadProcess thread;
 	
    // Object used for synchronizing gray images
 	private final Object lockEdge = new Object();
 	// Object used for synchronizing output image
 	private final Object lockOutput = new Object();

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.video);

        // Create an instance of Camera
        mCamera = getCameraInstance();
        
        // start image processing thread
  		thread = new ThreadProcess();
  		thread.start();
      		
        // Create our Preview view and set it as the content of our activity.
        mPreview = new CameraPreview(this, this, mCamera);
        mDraw = new Visualization(this);
		FrameLayout preview = (FrameLayout) findViewById(R.id.camera_preview);
        preview.addView(mPreview);
        preview.addView(mDraw);   
    }
    
    @Override
	protected void onPause() {
    	// stop the camera preview and all processing
		if (mCamera != null){
			mCamera.setPreviewCallback(null);
			mCamera.stopPreview();
			mCamera.release();
			mCamera = null;

			thread.stopThread();
			thread = null;
		}
		super.onPause();
	}

	public static Camera getCameraInstance(){
        Camera c = null;
        try {
            c = Camera.open(); // attempt to get a Camera instance
        }
        catch (Exception e){
            // Camera is not available (in use or does not exist)
        }
        return c; // returns null if camera is unavailable
    }
    
    private class Visualization extends SurfaceView {

		Activity activity;

		public Visualization(Activity context ) {
			super(context);
			this.activity = context;

			// This call is necessary, or else the
			// draw method will not be called.
			setWillNotDraw(false);
		}

		@Override
		protected void onDraw(Canvas canvas){
			int w = canvas.getWidth();
			int h = canvas.getHeight();
			
			synchronized ( lockOutput ) {
				if(mCamera != null) {
					Camera.Parameters param = mCamera.getParameters();
					Camera.Size s = param.getPreviewSize();
					
					// fill the window and center it
					double scaleX = w/(double)s.width;
					double scaleY = h/(double)s.height;
		
					double scale = Math.min(scaleX,scaleY);
					double tranX = (w-scale*s.width)/2;
					double tranY = (h-scale*s.height)/2;
		
					canvas.translate((float)tranX,(float)tranY);
					canvas.scale((float)scale,(float)scale);
					rectPaint.setColor(Color.argb(100, 255, 0, 0));
					rectPaint.setStrokeWidth(0);
					if(rects.size() > 0) {
						for(int i = 0; i < rects.size(); i++) {	
							canvas.drawRect(rects.get(i).left * SCALE_FACTOR, 
									rects.get(i).top * SCALE_FACTOR, 
									rects.get(i).right * SCALE_FACTOR, 
									rects.get(i).bottom * SCALE_FACTOR, 
									rectPaint);	
						}
					}
				}
			}
		}
	}

	@Override
	public void onPreviewFrame(byte[] data, Camera camera) {		
		
		// convert from NV21 format into Bitmap
		synchronized (lockEdge) {
			Camera.Parameters parameters = camera.getParameters(); 
	        Size size = parameters.getPreviewSize(); 
			ByteArrayOutputStream out = new ByteArrayOutputStream();
			YuvImage yuvImage = new YuvImage(data, parameters.getPreviewFormat(), size.width, size.height, null);
			yuvImage.compressToJpeg(new Rect(0, 0, size.width, size.height), 50, out);
			byte[] imageBytes = out.toByteArray();
			
			auxBmp = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
			bmp = Bitmap.createScaledBitmap(auxBmp, size.width / SCALE_FACTOR, size.height / SCALE_FACTOR, false);
		}
		// Can only do trivial amounts of image processing inside this function or else bad stuff happens.
		// To work around this issue most of the processing has been pushed onto a thread and the call below
		// tells the thread to wake up and process another image
		thread.interrupt();
	}
	
	/**
	 * External thread used to do more time consuming image processing
	 */
	private class ThreadProcess extends Thread {

		// true if a request has been made to stop the thread
		volatile boolean stopRequested = false;
		// true if the thread is running and can process more data
		volatile boolean running = true;

		/**
		 * Blocks until the thread has stopped
		 */
		public void stopThread() {
			stopRequested = true;
			while( running ) {
				thread.interrupt();
				Thread.yield();
			}
		}

		@Override
		public void run() {
			while( !stopRequested ) {

				// Sleep until it has been told to wake up
				synchronized ( Thread.currentThread() ) {
					try {
						wait();
					} catch (InterruptedException ignored) {}
				}

				// convert to edgeImg
				synchronized (lockEdge) {
					highContrastImage = ITBW.changeBitmapContrastBrightness(bmp, 1.4f, 0);
					edgeImg = TC.generateEdgeImage(highContrastImage, highContrastImage.getWidth(), highContrastImage.getHeight());
				}

				// render the output in a synthetic color image
				synchronized ( lockOutput ) {
					rects = TRD.textRegion(edgeImg);
				}
				
				mDraw.postInvalidate();
			}
			running = false;
		}
	}
}
