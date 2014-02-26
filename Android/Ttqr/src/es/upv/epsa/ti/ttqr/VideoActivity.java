package es.upv.epsa.ti.ttqr;

import java.io.ByteArrayOutputStream;
import java.util.List;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorMatrix;
import android.graphics.ColorMatrixColorFilter;
import android.graphics.Paint;
import android.graphics.Rect;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.view.SurfaceView;
import android.view.Window;
import android.widget.FrameLayout;
import android.graphics.YuvImage; 

/**
 * Demonstration of how to process a video stream on an Android device using BoofCV.  Most of the code below
 * is deals with handling Android and all of its quirks.  Video streams can be accessed in Android by processing
 * a camera preview.  Data from a camera preview comes in an NV21 image format, which needs to be converted.
 * After it has been converted it needs to be processed and then displayed.  Note that several locks are required
 * to avoid the three threads (GUI, camera preview, and processing) from interfering with each other.
 *
 * @author Peter Abeles
 */
@SuppressLint("NewApi")
public class VideoActivity extends Activity implements Camera.PreviewCallback {

	// camera and display objects
	private Camera mCamera;
	private Visualization mDraw;
	private CameraPreview mPreview;

	// Android image data used for displaying the results
	private Bitmap output;
	private Bitmap bmp;
	private Bitmap greyImage;
	private Bitmap highContrastImage;
	// temporary storage that's needed when converting from BoofCV to Android image data types
	private byte[] storage;

	// Thread where image data is processed
	private ThreadProcess thread;

	// Object used for synchronizing gray images
	private final Object lockGray = new Object();
	// Object used for synchronizing output image
	private final Object lockOutput = new Object();

	// if true the input image is flipped horizontally
	// Front facing cameras need to be flipped to appear correctly
	boolean flipHorizontal;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		requestWindowFeature(Window.FEATURE_NO_TITLE);
		setContentView(R.layout.video);

		// Used to visualize the results
		mDraw = new Visualization(this);

		// Create our Preview view and set it as the content of our activity.
		mPreview = new CameraPreview(this,this,true);

		FrameLayout preview = (FrameLayout) findViewById(R.id.camera_preview);

		preview.addView(mPreview);
		preview.addView(mDraw);
	}

	@Override
	protected void onResume() {
		super.onResume();
		setUpAndConfigureCamera();
	}

	@Override
	protected void onPause() {
		super.onPause();

		// stop the camera preview and all processing
		if (mCamera != null){
			mPreview.setCamera(null);
			mCamera.setPreviewCallback(null);
			mCamera.stopPreview();
			mCamera.release();
			mCamera = null;

			thread.stopThread();
			thread = null;
		}
	}

	/**
	 * Sets up the camera if it is not already setup.
	 */
	private void setUpAndConfigureCamera() {
		// Open and configure the camera
		mCamera = selectAndOpenCamera();

		Camera.Parameters param = mCamera.getParameters();
		param.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO);
		// Select the preview size closest to 320x240
		// Smaller images are recommended because some computer vision operations are very expensive
		List<Camera.Size> sizes = param.getSupportedPreviewSizes();
		Camera.Size s = sizes.get(closest(sizes,320,240));
		param.setPreviewSize(s.width,s.height);
		mCamera.setParameters(param);

		// declare image data
		output = Bitmap.createBitmap(s.width,s.height,Bitmap.Config.RGB_565 );
		bmp = Bitmap.createBitmap(s.width,s.height,Bitmap.Config.ARGB_8888 );
		//storage = ConvertBitmap.declareStorage(output, storage);

		// start image processing thread
		thread = new ThreadProcess();
		thread.start();

		// Start the video feed by passing it to mPreview
		mPreview.setCamera(mCamera);
	}

	/**
	 * Step through the camera list and select a camera.  It is also possible that there is no camera.
	 * The camera hardware requirement in AndroidManifest.xml was turned off so that devices with just
	 * a front facing camera can be found.  Newer SDK's handle this in a more sane way, but with older devices
	 * you need this work around.
	 */
	private Camera selectAndOpenCamera() {
		Camera.CameraInfo info = new Camera.CameraInfo();
		int numberOfCameras = Camera.getNumberOfCameras();

		int selected = -1;

		for (int i = 0; i < numberOfCameras; i++) {
			Camera.getCameraInfo(i, info);

			if( info.facing == Camera.CameraInfo.CAMERA_FACING_BACK ) {
				selected = i;
				flipHorizontal = false;
				break;
			} else {
				// default to a front facing camera if a back facing one can't be found
				selected = i;
				flipHorizontal = true;
			}
		}

		if( selected == -1 ) {
			dialogNoCamera();
			return null; // won't ever be called
		} else {
			return Camera.open(selected);
		}
	}

	/**
	 * Gracefully handle the situation where a camera could not be found
	 */
	private void dialogNoCamera() {
		AlertDialog.Builder builder = new AlertDialog.Builder(this);
		builder.setMessage("Your device has no cameras!")
				.setCancelable(false)
				.setPositiveButton("OK", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int id) {
						System.exit(0);
					}
				});
		AlertDialog alert = builder.create();
		alert.show();
	}

	/**
	 * Goes through the size list and selects the one which is the closest specified size
	 */
	public static int closest( List<Camera.Size> sizes , int width , int height ) {
		int best = -1;
		int bestScore = Integer.MAX_VALUE;

		for( int i = 0; i < sizes.size(); i++ ) {
			Camera.Size s = sizes.get(i);

			int dx = s.width-width;
			int dy = s.height-height;

			int score = dx*dx + dy*dy;
			if( score < bestScore ) {
				best = i;
				bestScore = score;
			}
		}

		return best;
	}

	/**
	 * Called each time a new image arrives in the data stream.
	 */
	@Override
	public void onPreviewFrame(byte[] bytes, Camera camera) {

		// convert from NV21 format into gray scale
		synchronized (lockGray) {
			Camera.Parameters parameters = camera.getParameters(); 
	        Size size = parameters.getPreviewSize(); 
			ByteArrayOutputStream out = new ByteArrayOutputStream();
			YuvImage yuvImage = new YuvImage(bytes, parameters.getPreviewFormat(), size.width, size.height, null);
			yuvImage.compressToJpeg(new Rect(0, 0, size.width, size.height), 50, out);
			byte[] imageBytes = out.toByteArray();
			
			bmp = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);

		}
		// Can only do trivial amounts of image processing inside this function or else bad stuff happens.
		// To work around this issue most of the processing has been pushed onto a thread and the call below
		// tells the thread to wake up and process another image
		thread.interrupt();
	}
	
	public Bitmap toGrayscale(Bitmap bmpOriginal)
	{        
	    int width, height;
	    height = bmpOriginal.getHeight();
	    width = bmpOriginal.getWidth();

	    Bitmap bmpGrayscale = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
	    Canvas c = new Canvas(bmpGrayscale);
	    Paint paint = new Paint();
	    ColorMatrix cm = new ColorMatrix();
	    cm.setSaturation(0);
	    ColorMatrixColorFilter f = new ColorMatrixColorFilter(cm);
	    paint.setColorFilter(f);
	    c.drawBitmap(bmpOriginal, 0, 0, paint);
	    return bmpGrayscale;
	}
	
	private Bitmap adjustedContrast(Bitmap src, double value)
	{
	    // image size
	    int width = src.getWidth();
	    int height = src.getHeight();
	    // create output bitmap

	    // create a mutable empty bitmap
	    Bitmap bmOut = Bitmap.createBitmap(width, height, src.getConfig());

	    // create a canvas so that we can draw the bmOut Bitmap from source bitmap
	    Canvas c = new Canvas();
	    c.setBitmap(bmOut);

	    // draw bitmap to bmOut from src bitmap so we can modify it
	    c.drawBitmap(src, 0, 0, new Paint(Color.BLACK));


	    // color information
	    int A, R, G, B;
	    int pixel;
	    // get contrast value
	    double contrast = Math.pow((100 + value) / 100, 2);

	    // scan through all pixels
	    for(int x = 0; x < width; ++x) {
	        for(int y = 0; y < height; ++y) {
	            // get pixel color
	            pixel = src.getPixel(x, y);
	            A = Color.alpha(pixel);
	            // apply filter contrast for every channel R, G, B
	            R = Color.red(pixel);
	            R = (int)(((((R / 255.0) - 0.5) * contrast) + 0.5) * 255.0);
	            if(R < 0) { R = 0; }
	            else if(R > 255) { R = 255; }

	            /*G = Color.green(pixel);
	            G = (int)(((((G / 255.0) - 0.5) * contrast) + 0.5) * 255.0);
	            if(G < 0) { G = 0; }
	            else if(G > 255) { G = 255; }

	            B = Color.blue(pixel);
	            B = (int)(((((B / 255.0) - 0.5) * contrast) + 0.5) * 255.0);
	            if(B < 0) { B = 0; }
	            else if(B > 255) { B = 255; }*/
		
	            // set new pixel color to output bitmap
	            bmOut.setPixel(x, y, Color.argb(A, R, R, R));
	        }
	    }
	    return bmOut;
	}
	
	public static Bitmap changeBitmapContrastBrightness(Bitmap bmp, float contrast, float brightness)
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

	    Paint paint = new Paint();
	    paint.setColorFilter(new ColorMatrixColorFilter(cm));
	    canvas.drawBitmap(bmp, 0, 0, paint);

	    return ret;
	}
	
	/**
	 * Draws on top of the video stream for visualizing computer vision results
	 */
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

			synchronized ( lockOutput ) {
				int w = canvas.getWidth();
				int h = canvas.getHeight();

				// fill the window and center it
				double scaleX = w/(double)output.getWidth();
				double scaleY = h/(double)output.getHeight();

				double scale = Math.min(scaleX,scaleY);
				double tranX = (w-scale*output.getWidth())/2;
				double tranY = (h-scale*output.getHeight())/2;

				canvas.translate((float)tranX,(float)tranY);
				canvas.scale((float)scale,(float)scale);

				// draw the image
				canvas.drawBitmap(output,0,0,null);
			}
		}
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

				// process the most recently converted image by swapping image buffered
				synchronized (lockGray) {
					greyImage = toGrayscale(bmp);
					highContrastImage = changeBitmapContrastBrightness(greyImage, 1.5f, 0);
				}

				// render the output in a synthetic color image
				synchronized ( lockOutput ) {
					output = new TextCleaner(highContrastImage).generateEdgeImage();
				}
				mDraw.postInvalidate();
			}
			running = false;
		}
	}
}
