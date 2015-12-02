package al.toast.plugins.ViewFile;


import java.io.*;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;


public class ViewFile extends CordovaPlugin {

	public static final String HANDLE_DOCUMENT_ACTION = "ViewFromUrl";

	@Override
	public boolean execute(String action, JSONArray args,
												 final CallbackContext callbackContext) throws JSONException {
		if (HANDLE_DOCUMENT_ACTION.equals(action)) {

      // parse arguments
      final JSONObject arg_object = args.getJSONObject(0);
      final String url = arg_object.getString("url");

      Context context = cordova.getActivity().getApplicationContext();

      try {
        // set intents and view file
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(url));
        context.startActivity(intent);

        callbackContext.success();
			} catch (ActivityNotFoundException e) {
				callbackContext.error("Activity Not Found");
			}

      return true;
    }

    return false;
  }
}
