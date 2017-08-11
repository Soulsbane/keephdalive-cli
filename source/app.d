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

immutable string WRITE_TO_LOCATIONS_FILENAME = "locations.dat";
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

	void loadWriteToLocations()
	{
		immutable string locationsFile = buildNormalizedPath(path_.getDir("config"), WRITE_TO_LOCATIONS_FILENAME);

		ensureFileExists(locationsFile, DEFAULT_LOCATIONS_DATA);
		immutable auto lines = locationsFile.readText.splitLines();

		foreach(filePath; lines)
		{
			addPath(filePath);
		}
	}

	bool addPath(const string path, const bool shouldWrite = false)
	{
		if(path.exists)
		{
			immutable string normalizedFilePath = buildNormalizedPath(path, writeToFileName_);
			immutable string locationsFile = buildNormalizedPath(path_.getDir("config"), WRITE_TO_LOCATIONS_FILENAME);
			immutable bool alreadyKnownLocation = locationAlreadyExists(path);

			if(!alreadyKnownLocation)
			{
				if(shouldWrite)
				{
					auto f = File(locationsFile, "a");
					f.writeln(path);
				}

				locations_ ~= path;
				writer_.addLocation(normalizedFilePath);

				writeln("Added new path: ", path);
			}
			else
			{
				writeln("That path already exists!");
			}

			return true;
		}
		else
		{
			return false;
		}
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
	bool locationAlreadyExists(const string path) const
	{
		return locations_.canFind(path);
	}

	string writeToFileName_ = DEFAULT_WRITE_TO_FILENAME;
	long fileWriteDelay_ = DEFAULT_FILE_WRITE_DELAY;
	string[] locations_;

	KeepAliveWriter writer_;
}

void main(string[] arguments)
{
	auto app = new KeepAliveApp;

	app.create("Raijinsoft", "keephdalive");
	app.loadWriteToLocations();
	app.handleCmdLineArguments(arguments);
}
