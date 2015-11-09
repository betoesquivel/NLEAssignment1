import java.util.StringTokenizer;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;

public class PreTokeniser {

	public static final String PUNCT = "!\"$%^&*()_+=#{}[];:'`/?,. \t\n";

   public static String tokenise(String line) {
	StringTokenizer st = new StringTokenizer(line,PUNCT,true);
	String tok1 = " ";
	String tok2 = " ";
	boolean skip = false;
	StringBuffer retval = new StringBuffer();
	while(st.hasMoreTokens()) {
		tok1 = tok2;
		tok2 = st.nextToken();
		if(",".equals(tok1)
		|| ".".equals(tok1)
		|| "-".equals(tok1)
		|| "'".equals(tok1)) {	// special punctuation mark
			if(Character.isWhitespace(tok2.charAt(0))) {
				tok1 = " "+tok1;
			} else {
				skip = true;
			}
		} else {
			if(skip == false) {
				tok1 = " "+tok1;
			}
			skip = false;
		}
		retval.append(tok1);
	}
	if(skip == false) {
		tok2 = " "+tok2;
	}
	retval.append(tok2);
	return(retval.toString());
   }

   public static void main( String args[] ) throws IOException {
	if( args.length < 1 )
		System.out.println("Usage: java PreTokeniser fileName ");
	else {
		BufferedReader in =
			new BufferedReader( new FileReader( args[0] ) );
		String line = in.readLine();
		while ( line != null ) {
			System.out.println( PreTokeniser.tokenise( line ) );
			line = in.readLine();
		}
	}
   }

} //end class PreTokeniser


