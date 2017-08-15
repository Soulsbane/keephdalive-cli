import std.stdio;
import std.file;
import std.string;
import std.path;
import std.datetime;
import std.algorithm;

import ctoptions;
import dapplicationbase;
import dfileutils;
import keephdalive.writer;

immutable string DEFAULT_LOCATIONS_DATA = "./\n";
immutable size_t DEFAULT_FILE_WRITE_DELAY = 5;
immutable string DEFAULT_WRITE_TO_FILENAME = "keephdalive.txt"; // TODO: Perhaps make it hidden.

struct Options
{
	@GetOptOptions("How many minutes to wait in between each write.")
	size_t delay = DEFAULT_FILE_WRITE_DELAY;
	@GetOptOptions("Name of the file to write to.")
	string filename = DEFAULT_WRITE_TO_FILENAME;
	@GetOptOptions("Add a path to the list of paths to be written to.", "ap", "add-path")
	string path;
}

class KeepAliveApp : Application!Options
{
public:
	this()
	{
		writer_ = new KeepAliveWriter;
	}

	bool addPath(const string path, const bool shouldWrite = false)
	{
		return writer_.addLocation(path, shouldWrite);
	}

	void startApplicationTimer()
	{
		fileWriteDelay_ = options_.getDelay(DEFAULT_FILE_WRITE_DELAY);
		writeToFileName_ = options_.getFilename(DEFAULT_WRITE_TO_FILENAME);

		debug
		{
			writer_.start(dur!("seconds")(fileWriteDelay_));
		}
		else
		{
			writer_.start(dur!("minutes")(fileWriteDelay_));
		}
	}

	override void onNoArguments()
	{
		saveOptions();
		startApplicationTimer();
	}

	override void onValidArguments()
	{
		if(options_.path != string.init)
		{
			immutable bool added = addPath(options_.path);

			if(added)
			{
				onNoArguments();
			}
			else
			{
				writeln("Error: That path does not exist!");
			}
		}
		else
		{
			onNoArguments();
		}
	}

private:
	string writeToFileName_ = DEFAULT_WRITE_TO_FILENAME;
	long fileWriteDelay_ = DEFAULT_FILE_WRITE_DELAY;
	string[] locations_;

	KeepAliveWriter writer_;

}

void main(string[] arguments)
{
	auto app = new KeepAliveApp;

	app.create("Raijinsoft", "keephdalive-cli");
	app.handleCmdLineArguments(arguments);
}
