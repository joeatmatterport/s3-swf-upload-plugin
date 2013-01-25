﻿package {	import flash.events.*;	import flash.external.*;	import flash.net.*;	import flash.display.*;	import flash.system.Security;	import com.nathancolgate.s3_swf_upload.*;	public class S3Uploader extends Sprite	{		//File Reference Vars		public var queue:S3Queue;		public var file:FileReference;		private var _multipleFileDialogBox:FileReferenceList;		private var _singleFileDialogBox:FileReference;		private var _fileFilter:FileFilter;		//config vars		private var _fileSizeLimit:Number;//bytes		private var _queueSizeLimit:Number;		private var _selectMultipleFiles:Boolean;		private var _enableLog:Boolean;		private var cssLoader:URLLoader;		public static var s3_swf_obj:String;		public function S3Uploader()		{			super();			S3Uploader.s3_swf_obj = LoaderInfo(root.loaderInfo).parameters.s3_swf_obj;			registerCallbacks();		}		private function registerCallbacks():void		{			if (ExternalInterface.available)			{				ExternalInterface.addCallback("init",init);				ExternalInterface.call(S3Uploader.s3_swf_obj + '.init');			}		}		public function consoleLog(logMessage:String):void		{			if (_enableLog)			{				ExternalInterface.call('console.log',logMessage);			}		}		private function init(signatureUrl:String,prefixPath:String,fileSizeLimit:Number,queueSizeLimit:Number,fileTypes:String,fileTypeDescs:String,selectMultipleFiles:Boolean,enableLog:Boolean,buttonWidth:Number,buttonHeight:Number,buttonUpUrl:String,buttonDownUrl:String,buttonOverUrl:String):void		{			consoleLog('Initializing...');			flash.system.Security.allowDomain("*");			// UI;			var browseButton:BrowseButton = new BrowseButton(buttonWidth,buttonHeight,buttonUpUrl,buttonDownUrl,buttonOverUrl);			addChild(browseButton);			stage.showDefaultContextMenu = false;			stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;			stage.align = flash.display.StageAlign.TOP_LEFT;			this.addEventListener(MouseEvent.CLICK,clickHandler);			// file dialog boxes			// We do two, so that we have the option to pick one or many			_fileSizeLimit = fileSizeLimit;			_fileFilter = new FileFilter(fileTypeDescs,fileTypes);			_queueSizeLimit = queueSizeLimit;			_selectMultipleFiles = selectMultipleFiles;			_enableLog = enableLog;			_multipleFileDialogBox = new FileReferenceList  ;			_singleFileDialogBox = new FileReference  ;			_multipleFileDialogBox.addEventListener(Event.SELECT,selectFileHandler);			_singleFileDialogBox.addEventListener(Event.SELECT,selectFileHandler);			// Setup Queue, File;			this.queue = new S3Queue(signatureUrl,prefixPath);			Globals.queue = this.queue;			ExternalInterface.addCallback("removeFileFromQueue",removeFileHandler);			consoleLog('Initialized');		}		// called when the browse button is clicked		// Browse for files		private function clickHandler(event:Event):void		{			consoleLog('clickHandler');			if ((_selectMultipleFiles == true))			{				consoleLog('Opening Multiple File Dialog box...');				_multipleFileDialogBox.browse([_fileFilter]);				consoleLog('Multiple File Dialog box Opened');			}			else			{				consoleLog('Opening Single File Dialog box...');				_singleFileDialogBox.browse([_fileFilter]);				consoleLog('Single File Dialog box Opened');			}		}		//  called after user selected files form the browse dialouge box.		private function selectFileHandler(event:Event):void		{			consoleLog('selectFileHandler');			var remainingSpots:int = _queueSizeLimit - this.queue.length;			var tooMany:Boolean = false;			if ((_selectMultipleFiles == true))			{				// Adding multiple files to the queue array				consoleLog('Adding multiple files to the queue array...');				if (event.currentTarget.fileList.length > remainingSpots)				{					tooMany = true;				}				var i:int;				for (i = 0; i < remainingSpots; i++)				{					consoleLog(((('Adding ' + (i + 1)) + ' of ') + remainingSpots) + ' files to the queue array...');					addFile(event.currentTarget.fileList[i]);					consoleLog((((i + 1) + ' of ') + remainingSpots) + ' files added to the queue array');				}				consoleLog('Multiple files added to the queue array');			}			else			{				// Adding one single file to the queue array				consoleLog('Adding single file to the queue array...');				if ((remainingSpots > 0))				{					addFile(FileReference(event.target));				}				else				{					tooMany = true;				}				consoleLog('Single file added to the queue array');			}			if ((tooMany == true))			{				if ((_queueSizeLimit == 1))				{					consoleLog("queueSizeLimit is 1, replace the file rather than error out.");					if (this.queue.length > 0)					{						this.queue.removeAll();						tooMany = false;					}					consoleLog("All files removed from queue, add current selection: " + this.queue.length);					addFile(event.currentTarget.fileList[0]);					consoleLog("After addfile.");				}				else				{					ExternalInterface.call(S3Uploader.s3_swf_obj + '.onQueueSizeLimitReached',this.queue.toJavascript());				}			}		}		// Add Selected File to Queue from file browser dialog box;		private function addFile(file:FileReference):void		{			consoleLog('addFile');			if (!file)			{				return;			}			if (checkFileSize(file.size))			{				consoleLog('Adding file to queue...');				this.queue.addItem(file);				consoleLog('File added to queue');				consoleLog('Calling onFileAdd...');				ExternalInterface.call(S3Uploader.s3_swf_obj + '.onFileAdd',toJavascript(file));				consoleLog('onFileAdd called');			}			else			{				consoleLog('Calling onFileSizeLimitReached...');				ExternalInterface.call(S3Uploader.s3_swf_obj + '.onFileSizeLimitReached',toJavascript(file));			}		}		// Remove File From Queue by index number;		private function removeFileHandler(index:Number):void		{			try			{				var del_file:FileReference = FileReference(this.queue.getItemAt(index));				this.queue.removeItemAt(index);				consoleLog('Calling onFileRemove...');				ExternalInterface.call(S3Uploader.s3_swf_obj + '.onFileRemove',del_file);				consoleLog('onFileRemove called');			}			catch (e:Error)			{				consoleLog('Calling onFileNotInQueue...');				ExternalInterface.call(S3Uploader.s3_swf_obj + '.onFileNotInQueue');			}			consoleLog('onFileNotInQueue called');		}		/* MISC */		// Checks the files do not exceed maxFileSize | if maxFileSize == 0 No File Limit Set		private function checkFileSize(filesize:Number):Boolean		{			var r:Boolean = false;			//if  filesize greater then maxFileSize			if ((filesize > _fileSizeLimit))			{				r = false;			}			else if ((filesize <= _fileSizeLimit))			{				r = true;			}			if ((_fileSizeLimit == 0))			{				r = true;			}			return r;		}		// Turns a FileReference into an Object so that ExternalInterface doesn't choke		private function toJavascript(file:FileReference):Object		{			var javascriptable_file:Object = new Object  ;			javascriptable_file.name = file.name;			javascriptable_file.size = file.size;			javascriptable_file.type = file.type;			return javascriptable_file;		}	}}