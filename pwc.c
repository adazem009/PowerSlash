/*
 * PowerSlash compiler - C version
 *
 * Copyright (C) 2021 - adazem009
 *
 * PowerSlash is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * PowerSlash is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<errno.h>
#include<stdbool.h>
#include<dirent.h>
void print_usage(char *cmdarg)
{
	printf("Usage:\n%s <file>\n",cmdarg);
}
int _lastchar(char *input, char c)
{
	int i,out=0;
	for(i=0; i<strlen(input); i++)
		if(input[i] == c)
			out=i;
	return out;
}
char *_f_name_ext(char *fname, int option)
{
	char part[255]="",name[255],ext[255],*str_to_ret;
	int i=0, last=_lastchar(fname,'.');
	bool dot=false;
	for(i=0; i<strlen(fname); i++)
	{
		if((fname[i] == '.') && (i == last))
		{
			strcpy(name,part);
			strcpy(part,"");
			dot=true;
		}
		else
			strncat(part,&fname[i],1);
	}
	if(dot)
		strcpy(ext,part);
	else
	{
		strcpy(ext,"");
		strcpy(name,part);
	}
	switch(option)
	{
		case 0:
			str_to_ret = malloc(sizeof(char) * sizeof(name));
			strcpy(str_to_ret,name);
			break;
		case 1:
			str_to_ret = malloc(sizeof(char) * sizeof(ext));
			strcpy(str_to_ret,ext);
			break;
		default:
			return NULL;
			break;
	}
	return str_to_ret;
}
int _lcount(char *fname)
{
	int lc=0;
	char c;
	FILE *fr;
	fr=fopen(fname,"r");
	while((c=getc(fr)) != EOF)
		if(c == '\n')
			lc++;
	fclose(fr);
	return lc;
}
void _error(char *desc, bool showline, int line, int exitc, char *infn)
{
	if(strcmp(infn,"") == 0)
		printf("error: ");
	else
		printf("%s: error: ",infn);
	if(showline)
		printf("%d: ",line);
	printf("%s\n",desc);
	exit(exitc);
}
char *_getinput(const int arg, const int input, int i, int argc,const char *raw)
{
	int argn,inputc,inputn,tmpinput_alloc=256;
	char tmpnum[16000];
	char *tmpinput = (char*) malloc(tmpinput_alloc);
	// Read args
	for(argn=0;argn<argc;argn++)
	{
		// Get input count
		strcpy(tmpnum,"");
		while(raw[i] != '\n')
		{
			strncat(tmpnum,&raw[i],1);
			i++;
		}
		inputc=strtol(tmpnum,NULL,10);
		i++;
		// Read inputs
		for(inputn=0;inputn<inputc;inputn++)
		{
			strcpy(tmpinput,"");
			while(raw[i] != '\n')
			{
				if(strlen(tmpinput)+1 > tmpinput_alloc)
				{
					tmpinput = (char*) realloc(tmpinput,strlen(tmpinput)+1);
					tmpinput_alloc++;
				}
				strncat(tmpinput,&raw[i],1);
				i++;
			}
			if((arg == argn) && (input == inputn))
			{
				return tmpinput;
			}
			i++;
		}
	}
	return "";
}
int _getinputc(const int arg, int i, int argc,const char *raw)
{
	int argn,inputc,inputn;
	char tmpnum[16000];
	// Read args
	for(argn=0;argn<argc;argn++)
	{
		// Get input count
		strcpy(tmpnum,"");
		while(raw[i] != '\n')
		{
			strncat(tmpnum,&raw[i],1);
			i++;
		}
		inputc=strtol(tmpnum,NULL,10);
		i++;
		if(arg == argn)
			return inputc;
		// Read inputs
		for(inputn=0;inputn<inputc;inputn++)
		{
			while(raw[i] != '\n')
				i++;
			i++;
		}
	}
	return 0;
}
char *_process_if(char *raw, int i, int line, int cmd_argc, char *filename)
{
	int arg_inputc,in_i,in_i2;
	char err[64],part[10240],part2[16],part3[10240],part4[10240],val1[512],op[3],val2[512],gate[4];
	char quote;
	bool negate;
	if(cmd_argc != 1)
		_error("Number of arguments must be 1",true,line+1,12,"");
	strcpy(part,_getinput(0,0,i,cmd_argc,raw));
	strcpy(part3,"");
	in_i2=0; // number of arguments in compiled code
	in_i=0;
	while(in_i < strlen(part))
	{
		if((part[in_i] != '[') && (part[in_i] != '!'))
			_error("Syntax error",true,line+1,14,filename);
		while((in_i < strlen(part)) && (part[in_i] != ']'))
		{
			// Check, if there's a negation
			negate=(part[in_i] == '!');
			// Skip negation
			if(negate)
				in_i++;
			// Skip '['
			in_i++;
			// Read value 1
			strcpy(val1,"");
			while((in_i < strlen(part)) && (part[in_i] != ']') && (part[in_i] != '=') && (part[in_i] != '!') && (part[in_i] != '>') && (part[in_i] != '<'))
			{
				strncat(val1,&part[in_i],1);
				if((part[in_i] == '"') || (part[in_i] == '\''))
				{
					quote=part[in_i];
					do
					{
						in_i++;
						strncat(val1,&part[in_i],1);
					}while(part[in_i] != quote);
				}
				in_i++;
			}
			if((strcmp(val1,"false") == 0) || (strcmp(val1,"true") == 0) || (strcmp(val1,"0") == 0) || (strcmp(val1,"1") == 0))
			{
				// Compile
				if(negate)
				{
					if((strcmp(val1,"false") == 0) || (strcmp(val1,"0") == 0))
						sprintf(part4,"3\n0\n\"==\"\n0\n");
					else
						sprintf(part4,"4\n0\n\"==\"\n0\n'!'\n");
				}
				else
				{
					if((strcmp(val1,"true") == 0) || (strcmp(val1,"1") == 0))
						sprintf(part4,"3\n0\n\"==\"\n0\n");
					else
						sprintf(part4,"4\n0\n\"==\"\n0\n'!'\n");
				}
				strcat(part3,part4);
				in_i2++;
			}
			else
			{
				// Read operator
				strcpy(op,"");
				while((in_i < strlen(part)) && ((part[in_i] == '=') || (part[in_i] == '!') || (part[in_i] == '>') || (part[in_i] == '<')))
				{
					strncat(op,&part[in_i],1);
					in_i++;
				}
				if((strcmp(op,"==") != 0) && (strcmp(op,"!=") != 0) && (strcmp(op,">") != 0) && (strcmp(op,"!>") != 0) && (strcmp(op,">=") != 0) && (strcmp(op,"!>=") != 0) && (strcmp(op,"<") != 0) && (strcmp(op,"!<") != 0) && (strcmp(op,"<=") != 0) && (strcmp(op,"!<=") != 0))
				{
					sprintf(err,"Unknown operator: '%s'",op);
					_error(err,true,line+1,15,filename);
				}
				// Read value 2
				strcpy(val2,"");
				while((in_i < strlen(part)) && (part[in_i] != ']') && (part[in_i] != '=') && (part[in_i] != '!') && (part[in_i] != '>') && (part[in_i] != '<'))
				{
					strncat(val2,&part[in_i],1);
					if((part[in_i] == '"') || (part[in_i] == '\''))
					{
						quote=part[in_i];
						do
						{
							in_i++;
							strncat(val2,&part[in_i],1);
						}while(part[in_i] != quote);
					}
					in_i++;
				}
				// Compile
				if(negate)
					sprintf(part4,"4\n%s\n\"%s\"\n%s\n'!'\n",val1,op,val2);
				else
					sprintf(part4,"3\n%s\n\"%s\"\n%s\n",val1,op,val2);
				strcat(part3,part4);
				in_i2++;
			}
		}
		if(part[in_i] != ']')
			_error("Syntax error",true,line+1,14,filename);
		in_i++;
		// Read gate
		if(in_i < strlen(part))
		{
			strcpy(gate,"");
			while((in_i < strlen(part)) && (part[in_i] != '[') && (part[in_i] != '!'))
			{
				strncat(gate,&part[in_i],1);
				in_i++;
			}
			if(strcmp(gate,"and") == 0)
				strcpy(gate,"&&");
			else if(strcmp(gate,"nand") == 0)
				strcpy(gate,"!&");
			else if(strcmp(gate,"or") == 0)
				strcpy(gate,"||");
			else if(strcmp(gate,"nor") == 0)
				strcpy(gate,"!|");
			else if(strcmp(gate,"xor") == 0)
				strcpy(gate,"//");
			else if(strcmp(gate,"xnor") == 0)
				strcpy(gate,"!/");
			else
			{
				sprintf(err,"Gate '%s' not found",gate);
				_error(err,true,line+1,16,filename);
			}
			// Compile
			sprintf(part4,"1\n\"%s\"\n",gate);
			strcat(part3,part4);
			in_i2++;
		}
	}
	// Add arg count
	sprintf(part4,"%d\n",in_i2);
	strcat(part4,part3);
	strcpy(part3,part4);
	// Return output
	char *str_to_ret = malloc(sizeof(char) * sizeof(part3));
	strcpy(str_to_ret,part3);
	return str_to_ret;
}
char *_getcontent(const char *input, int line, char *filename)
{
	if((input[0] != '"') && (input[0] != '\''))
		_error("Can't get content from a variable",true,line+1,14,filename);
	if(input[strlen(input)-1] != input[0])
		_error("Missing end quote",true,line+1,14,filename);
	char quote;
	int i,out_alloc=128;
	char *out = (char*) malloc(out_alloc);
	strcpy(out,"");
	for(i=0; i < strlen(input); i++)
	{
		if((input[i] == '"') || (input[i] == '\''))
		{
			quote=input[i];
			i++;
			while((input[i] != quote) && (i < strlen(input)))
			{
				if((strlen(out)+1) > out_alloc)
				{
					out = (char*) realloc(out,strlen(out)+1);
					out_alloc++;
				}
				strncat(out,&input[i],1);
				i++;
			}
		}
		else
			strncat(out,&input[i],1);
	}
	return out;
}
int _input_type(char *input)
{
	char check[strlen(input)*sizeof(char)];
	int i;
	bool isnum;
	if((input[0] == '"') || (input[0] == '\''))
		return 0;
	else
	{
		isnum=true;
		for(i=0; i<strlen(input); i++)
		{
			switch(input[i]) {
				case '0':
					break;
				case '1':
					break;
				case '2':
					break;
				case '3':
					break;
				case '4':
					break;
				case '5':
					break;
				case '6':
					break;
				case '7':
					break;
				case '8':
					break;
				case '9':
					break;
				case '.':
					break;
				default:
				{
					isnum=false;
					i=strlen(input);
					break;
				}
			}
		}
		if(isnum)
			return 1;
		else
			return 2;
	}
}
void endstrconv(char *infn, char *outfn, char *mode)
{
	int line_alloc=64;
	char *line = (char*) malloc(line_alloc);
	strcpy(line,"");
	char c;
	FILE *ir = fopen(infn,"r");
	FILE *ow = fopen(outfn,mode);
	while((c=getc(ir)) != EOF)
	{
		if(c == '\n')
		{
			fprintf(ow,"%ld;%s",strlen(line),line);
			strcpy(line,"");
		}
		else
		{
			if((strlen(line)+2) > line_alloc)
			{
				line = (char*) realloc(line,strlen(line)+2);
				line_alloc=strlen(line)+2;
			}
			strncat(line,&c,1);
		}
	}
	fclose(ir);
	fclose(ow);
}
int main(int argc, char *argv[])
{
	int filesize,i,i2=0,i3,argn,inputn,line,input_alloc,arg_alloc,fullcmd_alloc,raw_alloc,linec=0,comment;
	char filename[255],outfn[255],c='\0',newl='\n',conv[10240],conv2[10240],cmd[32],quote,err[128],print_in[102400],print_in2[102400],include_dir[255];
	bool strconv=false,forceinclude=false;
	if(argc < 2)
	{
		print_usage(argv[0]);
		exit(1);
	}
	strcpy(filename,"");
	strcpy(outfn,"");
	strcpy(include_dir,"include");
	// Read args
	for(i=1;i<argc;i++)
	{
		if(strcmp(argv[i],"-o") == 0)
		{
			// Output file name option
			if(i+1 == argc)
			{
				printf("%s: missing output file operand\n",argv[0]);
				exit(1);
			}
			i++;
			strcpy(outfn,argv[i]);
		}
		else if(strcmp(argv[i],"--string") == 0)
		{
			// Convert to one-line string after compilation
			strconv=true;
		}
		else if(strcmp(argv[i],"--include") == 0)
		{
			// Include option (don't remove .functions directory, etc.)
			forceinclude=true;
		}
		else if(strcmp(argv[i],"--include-dir") == 0)
		{
			// Custom include dir
			if(i+1 == argc)
			{
				printf("%s: missing path\n",argv[0]);
				exit(1);
			}
			i++;
			strcpy(include_dir,argv[i]);
		}
		else
		{
			if(argv[i][0] == '-')
			{
				printf("%s: unknown option: '%s'\n",argv[0],argv[i]);
				exit(1);
			}
			strcpy(filename,argv[i]);
		}
	}
	if(strcmp(filename,"") == 0)
	{
		printf("%s: missing input file operand\n",argv[0]);
		exit(1);
	}
	if(strcmp(outfn,"") == 0)
	{
		// Default output file name
		if(strcmp(_f_name_ext(filename,1),"smc") == 0)
		{
			strcpy(outfn,filename);
			strcat(outfn,".smc");
		}
		else
			sprintf(outfn,"%s.smc",_f_name_ext(filename,0));
	}
	FILE *fr;
	fr=fopen(filename,"r");
	if(errno != 0)
	{
		printf("%s: %s: %s\n",argv[0],filename,strerror(errno));
		exit(2);
	}
	// Get file size
	fseek(fr,0L,SEEK_END);
	filesize=ftell(fr);
	rewind(fr);
	// Get number of lines
	linec=_lcount(filename);
	// Init alloc vars
	input_alloc=128;
	arg_alloc=256;
	fullcmd_alloc=512;
	raw_alloc=1024;
	// Allocate memory
	char *input = (char*) malloc(input_alloc);
	char *arg = (char*) malloc(arg_alloc);
	char *fullcmd = (char*) malloc(fullcmd_alloc);
	char *raw = (char*) malloc(raw_alloc);
	// Initialise strings
	strcpy(input,"");
	strcpy(arg,"");
	strcpy(fullcmd,"");
	strcpy(raw,"");
	// Lines array
	int flines[linec];
	memset(flines,0,linec*sizeof(int));
	// Convert to raw program
	line=0;
	while(c != EOF)
	{
		// Read line
		if(c != EOF)
			c='\0';
		strcpy(fullcmd,"");
		comment=0;
		argn=0;
		while((c != '\n') && (c != EOF))
		{
			// Read arg
			if((c != EOF) && (c != '\n'))
				c='\0';
			strcpy(arg,"");
			inputn=0;
			while((c != '/') && (c != '\n') && (c != EOF))
			{
				// Read input
				if((c != EOF) && (c != '\n') && (c != '/'))
					c='\0';
				strcpy(input,"");
				while((c != ',') && (c != '/') && (c != '\n') && (c != EOF))
				{
					c=getc(fr);
					if(c == '/')
					{
						c=getc(fr);
						if(c == '/')
						{
							comment=1;
							fseek(fr, -2, SEEK_CUR);
							c=getc(fr);
						}
						else
						{
							fseek(fr, -2, SEEK_CUR);
							c=getc(fr);
						}
					}
					if((c != ' ') && (c != '	') && (c != ',') && (c != '/') && (c != '\n') && (c != EOF))
					{
						if((strlen(input)+2) > input_alloc)
						{
							input = (char*) realloc(input,(strlen(input)+2));
							input_alloc=strlen(input)+2;
						}
						strncat(input,&c,1);
						if((c == '"') || (c == '\''))
						{
							quote=c;
							c='\0';
							while((c != quote) && (c != '\n') && (c != EOF))
							{
								c=getc(fr);
								if((strlen(input)+2) > input_alloc)
								{
									input = (char*) realloc(input,(strlen(input)+2));
									input_alloc=strlen(input)+2;
								}
								strncat(input,&c,1);
							}
						}
					}
				}
				if(comment == 0)
				{
					// Add input
					strncat(input,&newl,1);
					if((strlen(arg) + strlen(input) + 2) > arg_alloc)
					{
						arg = (char*) realloc(arg,(strlen(arg) + strlen(input) + 2));
						arg_alloc = strlen(arg) + strlen(input) + 2;
					}
					strcat(arg,input);
					inputn++;
				}
			}
			if((c != EOF) && (comment == 0))
			{
				if(argn == 0)
				{
					// This arg is command/function name
					flines[i2]=line;
					i2++;
					if(inputn != 1)
						_error("Incorrect function name syntax",true,line+1,10,filename);
					strcpy(cmd,input);
					// Remove last character (newline)
					cmd[strlen(cmd)-1]='\0';
				}
				else
				{
					// Add input count
					sprintf(conv,"%d",inputn);
					strncat(conv,&newl,1);
					strcat(conv,arg);
					if((strlen(conv)+2) > arg_alloc)
					{
						arg = (char*) realloc(arg,(strlen(conv)+2));
						arg_alloc=strlen(conv)+2;
					}
					strcpy(arg,conv);
					// Add arg
					if((strlen(fullcmd) + strlen(arg) + 2) > fullcmd_alloc)
					{
						fullcmd = (char*) realloc(fullcmd,(strlen(fullcmd) + strlen(arg) + 2));
						fullcmd_alloc = strlen(fullcmd) + strlen(arg) + 2;
					}
					strcat(fullcmd,arg);
				}
				argn++;
			}
		}
		if((c != EOF) && (comment == 0))
		{
			// Add function name
			strcpy(conv,cmd);
			strncat(conv,&newl,1);
			// Add arg count
			// Must be argn-1 here because the first arg is the function name
			sprintf(conv2,"%d",argn-1);
			strcat(conv,conv2);
			strncat(conv,&newl,1);
			strcat(conv,fullcmd);
			strcpy(fullcmd,conv);
			// Add line
			if((strlen(raw) + strlen(fullcmd) + 2) > raw_alloc)
			{
				raw = (char*) realloc(raw,(strlen(raw) + strlen(fullcmd) + 2));
				raw_alloc = strlen(raw) + strlen(fullcmd) + 2;
			}
			strcat(raw,fullcmd);
			// Exception for print>
			if(strcmp(cmd,"print>") == 0)
			{
				// Read every line
				strcpy(print_in2,"");
				strcpy(print_in,"");
				while((c != EOF) && (strcmp(print_in,"<print") != 0))
				{
					line++;
					// Read line
					i3=0;
					c='\0';
					while((c != '\n') && (c != EOF))
					{
						// Read input
						strcpy(print_in,"");
						c='\0';
						while((c != '\n') && (c != EOF) && (c != ','))
						{
							c=getc(fr);
							if(c == '/')
								_error("Syntax error",true,line+1,14,filename);
							if((c != '\n') && (c != ',') && (c != ' ') && (c != '	'))
							{
								if((c == '"') || (c == '\''))
								{
									strncat(print_in,&c,1);
									quote=c;
									c='\0';
									while((c != quote) && (c != '\n'))
									{
										c=getc(fr);
										strncat(print_in,&c,1);
									}
								}
								else
									strncat(print_in,&c,1);
							}
						}
						if(strcmp(print_in,"<print") == 0)
						{
							if((i3 != 0) || (c != '\n'))
							{
								_error("Syntax error",true,line+1,14,filename);
							}
							flines[i2]=line;
							i2++;
							strcat(print_in2,"<print\n0\n");
						}
						else
						{
							flines[i2]=line;
							i2++;
							strcat(print_in2,"print\n1\n1\n");
							strcat(print_in2,print_in);
							strcat(print_in2,"\n");
						}
						i3++;
					}
					flines[i2]=line;
					i2++;
					strcat(print_in2,"print\n1\n1\n\\n\n");
				}
				if((strlen(raw) + strlen(print_in2) + 2) > raw_alloc)
				{
					raw = (char*) realloc(raw,(strlen(raw) + strlen(print_in2) + 2));
					raw_alloc = strlen(raw) + strlen(print_in2) + 2;
				}
				strcat(raw,print_in2);
			}
			// Exception for <print
			else if(strcmp(cmd,"<print") == 0)
				_error("Expected 'print>' but got '<print'",true,line+1,14,filename);
		}
		line++;
	}
	// Free memory
	free(input);
	free(arg);
	free(fullcmd);
	//printf("%s",raw);
	// Open output file
	FILE *ow, *funcr;
	ow=fopen(outfn,"w");
	// Compile all commands
	int cmd_argc,arg_inputc,in_i,in_i2,in_tmp,col,col2,bold,italic,underlined,func_type=0,linkdef_type=0;
	char part[10240],part2[16],part3[10240],part4[10240],val1[512],op[3],val2[512],gate[4],func_name[255],linkdef_var_name[32];
	strcpy(func_name,"");
	strcpy(linkdef_var_name,"");
	bool _def=false,_def_started=false;
	DIR *funcdir = opendir(".functions");
	if(funcdir)
	{
		closedir(funcdir);
		if(!(forceinclude))
		{
			system("rm -rf .functions");
			system("mkdir .functions");
		}
	}
	else
	{
		if(forceinclude)
			_error("--include is unavailable right now",false,0,3,filename);
		system("mkdir .functions");
	}
	i=0;
	i2=0;
	while(i < strlen(raw))
	{
		// Read function name
		strcpy(cmd,"");
		do
		{
			strncat(cmd,&raw[i],1);
			i++;
		} while((raw[i] != '\n') && (i < strlen(raw)));
		line=flines[i2];
		i2++;
		// Skip newline
		i++;
		// Read arg count
		strcpy(part2,"");
		do
		{
			strncat(part2,&raw[i],1);
			i++;
		} while((raw[i] != '\n') && (i < strlen(raw)));
		cmd_argc=strtol(part2,NULL,10);
		// Skip newline
		i++;
		// Functions
		sprintf(part,".functions/%s",cmd);
		if((funcr=fopen(part,"r")) && !(_def && !(_def_started)))
		{
			if((strcmp(cmd,func_name) == 0) && (_def == true))
			{
				sprintf(err,"Can not use a function that is currently being defined\nUse 'linkdef' with the 'source' function to fix this");
				_error(err,true,line+1,14,filename);
			}
			if((c=getc(funcr)) == 'L')
			{
				getc(funcr);
				strcpy(part,"");
				while((c != '\n') && (c != EOF))
				{
					c=getc(funcr);
					if((c != '\n') && (c != EOF))
						strncat(part,&c,1);
				}
				fprintf(ow,"1B\n%d\n1\n%s\n",cmd_argc+1,part);
				for(in_i=0; in_i < cmd_argc; in_i++)
				{
					fprintf(ow,"%d\n",_getinputc(in_i,i,cmd_argc,raw));
					for(in_i2=0; in_i2 < _getinputc(in_i,i,cmd_argc,raw); in_i2++)
						fprintf(ow,"%s\n",_getinput(in_i,in_i2,i,cmd_argc,raw));
				}
			}
			else
			{
				rewind(funcr);
				fprintf(ow,"10\n1\n2\n\"arg_count\"\n%d\n",cmd_argc);
				for(in_i=0; in_i < cmd_argc; in_i++)
				{
					fprintf(ow,"14\n2\n1\n\"arg_%d\"\n%d\n",in_i+1,_getinputc(in_i,i,cmd_argc,raw));
					for(in_i2=0; in_i2 < _getinputc(in_i,i,cmd_argc,raw); in_i2++)
						fprintf(ow,"%s\n",_getinput(in_i,in_i2,i,cmd_argc,raw));
				}
				while((c=getc(funcr)) != EOF)
					putc(c,ow);
				fclose(funcr);
			}
		}
		else if(strcmp(cmd,"exit") == 0)
		{
			// exit
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"0\n");
		}
		else if(strcmp(cmd,"repeat") == 0)
		{
			// repeat/count
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_input_type(_getinput(0,0,i,cmd_argc,raw)) == 0)
			{
				printf("%s: %d: warning: expected integer without quotes\n",filename,line+1);
				fprintf(ow,"1\n0\n%s\n",_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
			}
			else if(_input_type(_getinput(0,0,i,cmd_argc,raw)) == 1)
				fprintf(ow,"1\n0\n%s\n",_getinput(0,0,i,cmd_argc,raw));
			else
				fprintf(ow,"1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"endloop") == 0)
		{
			// endloop
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"3\n0\n");
		}
		else if(strcmp(cmd,"if") == 0)
		{
			// if/![value operator value] gate [value operator value] ...
			fprintf(ow,"4\n%s",_process_if(raw,i,line,cmd_argc,filename));
		}
		else if(strcmp(cmd,"endif") == 0)
		{
			// endif
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"5\n0\n");
		}
		else if(strcmp(cmd,"else") == 0)
		{
			// else
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"6\n0\n");
		}
		else if(strcmp(cmd,"print") == 0)
		{
			// print/string,\n,\ccolor,\bbold_value,\iitalic_value,\uunderlined_value
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			col=0;
			bold=0;
			italic=0;
			underlined=0;
			for(in_i=0; in_i < _getinputc(0,i,cmd_argc,raw); in_i++)
			{
				strcpy(part,_getinput(0,in_i,i,cmd_argc,raw));
				if(part[0] == '\\')
				{
					if(part[1] == 'n')
						fprintf(ow,"m2\n");
					else if(part[1] == 'c')
					{
						strcpy(part3,"");
						for(in_i2=2; in_i2 < strlen(part); in_i2++)
							strncat(part3,&part[in_i2],1);
						// TODO: Add color support
						//fprintf(ow,"21\n1\n1\n%s\n",part3);
						printf("%s: %d: warning: colors have not been implemented yet\n",filename,line+1);
						col=1;
					}
					else if((part[1] == 'b') || (part[1] == 'i') || (part[1] == 'u'))
					{
						printf("%s: %d: warning: text style is deprecated\n",filename,line+1);
					}
					else
					{
						sprintf(err,"Unknown backslash escape: '\\%c'",part[1]);
						_error(err,true,line+1,17,filename);
					}
				}
				else
				{
					if(_input_type(part) == 0)
						fprintf(ow,"m1\n0\n%s\n",_getcontent(part,line,filename));
					else if(_input_type(part) == 1)
						fprintf(ow,"m1\n0\n%s\n",part);
					else
						fprintf(ow,"m1\n1\n%s\n",part);
				}
			}
			// TODO: Add color support
			//if(col == 1)
			//	fprintf(ow,"21\n1\n1\n255255255\n");
		}
		else if(strcmp(cmd,"read") == 0)
		{
			// read/string,output_var/string,output_var/...
			if(cmd_argc == 0)
				_error("No arguments",true,line+1,12,filename);
			for(in_i=0;in_i<cmd_argc;in_i++)
			{
				// Read arg
				if(_getinputc(in_i,i,cmd_argc,raw) != 2)
				{
					sprintf(err,"Number of inputs in argument n. %d must be 2",in_i+1);
					_error(err,true,line+1,13,filename);
				}
				fprintf(ow,"m6\n");
				if(_input_type(_getinput(in_i,0,i,cmd_argc,raw)) == 0)
					fprintf(ow,"0\n%s\n",_getcontent(_getinput(in_i,0,i,cmd_argc,raw),line,filename));
				else if(_input_type(_getinput(in_i,0,i,cmd_argc,raw)) == 1)
					fprintf(ow,"0\n%s\n",_getinput(in_i,0,i,cmd_argc,raw));
				else
					fprintf(ow,"1\n%s\n",_getinput(in_i,0,i,cmd_argc,raw));
				if(_input_type(_getinput(in_i,1,i,cmd_argc,raw)) == 0)
					fprintf(ow,"0\n%s\n",_getcontent(_getinput(in_i,1,i,cmd_argc,raw),line,filename));
				else if(_input_type(_getinput(in_i,1,i,cmd_argc,raw)) == 1)
					fprintf(ow,"0\n%s\n",_getinput(in_i,1,i,cmd_argc,raw));
				else
					fprintf(ow,"1\n%s\n",_getinput(in_i,1,i,cmd_argc,raw));
			}
		}
		else if(strcmp(cmd,"keywait") == 0)
		{
			// keywait/key,wait_for_release_(0_or_1)
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) == 1)
				fprintf(ow,"C\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
			else if(_getinputc(0,i,cmd_argc,raw) == 2)
				fprintf(ow,"C\n1\n2\n%s\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
			else
				_error("Number of inputs in the first argument must be 1 or 2",true,line+1,13,filename);
		}
		else if(strcmp(cmd,"clear") == 0)
		{
			// clear
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"m3\n");
		}
		else if(strcmp(cmd,"calc") == 0)
		{
			// calc/expression
			if((cmd_argc != 1) && (cmd_argc != 2))
				_error("Number of arguments must be 1 or 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(cmd_argc == 2)
				if(_getinputc(1,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			strcpy(part,_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
			in_i=0;
			// Get variable name
			strcpy(part2,"");
			while((part[in_i] != '=') && (in_i < strlen(part)))
			{
				if((part[in_i] == '+') || (part[in_i] == '-') || (part[in_i] == '*') || (part[in_i] == '/') || (part[in_i] == '(') || (part[in_i] == ')'))
					_error("Syntax error",true,line+1,14,filename);
				strncat(part2,&part[in_i],1);
				in_i++;
			}
			if(part[in_i] != '=')
				_error("Syntax error",true,line+1,14,filename);
			// Skip '='
			in_i++;
			// Read right side
			strcpy(part3,"");
			strcpy(val1,"");
			strcpy(val2,"");
			in_i2=0; // tmp_calc ID
			while(in_i < strlen(part))
			{
				if((part[in_i] == '+') || (part[in_i] == '-'))
				{
					if((in_i+1) == strlen(part))
					{
						_error("Syntax error",true,line+1,14,filename);
					}
					if(strcmp(val1,"") == 0)
					{
						strcpy(val1,part3);
						strcpy(part3,"");
						if(part[in_i] == '+')
							strcpy(op,"1");
						else if(part[in_i] == '-')
							strcpy(op,"2");
					}
					else if(strcmp(val2,"") == 0)
					{
						strcpy(val2,part3);
						strcpy(part3,"");
						if(part[in_i] == '+')
							strcpy(op,"1");
						else if(part[in_i] == '-')
							strcpy(op,"2");
						sprintf(part4,"tmp_calc%d",in_i2);
						fprintf(ow,"F\n3\n1\n%s\n1\n\"%s\"\n2\n%s\n%s\n",op,part4,val1,val2);
						in_i2++;
						strcpy(val1,part4);
						strcpy(val2,"");
					}
				}
				else if((part[in_i] == '*') || (part[in_i] == '/'))
				{
					sprintf(err,"Not supported.");
					if(part[in_i] == '*')
						strcat(err,"\nUse the 'multi' function instead.");
					else if(part[in_i] == '/')
						strcat(err,"\nUse the 'div' function instead.");
					_error(err,true,line+1,18,filename);
				}
				else if((part[in_i] == '(') || (part[in_i] == ')'))
					_error("Brackets are not supported",true,line+1,18,filename);
				else
					strncat(part3,&part[in_i],1);
				in_i++;
			}
			strcpy(val2,part3);
			if(cmd_argc == 2)
				fprintf(ow,"F\n4\n1\n%s\n1\n\"%s\"\n2\n%s\n%s\n1\n%s\n",op,part2,val1,val2,_getinput(1,0,i,cmd_argc,raw));
			else
				fprintf(ow,"F\n3\n1\n%s\n1\n\"%s\"\n2\n%s\n%s\n",op,part2,val1,val2);
		}
		else if(strcmp(cmd,"set") == 0)
		{
			// set/var,value/var,value/...
			if(cmd_argc == 0)
				_error("Number of arguments must be at least 1",true,line+1,12,filename);
			for(in_i=0;in_i<cmd_argc;in_i++)
			{
				in_tmp=_getinputc(in_i,i,cmd_argc,raw);
				if(in_tmp < 2)
				{
					sprintf(err,"Number of inputs in argument n. %d must be at least 2",in_i+1);
					_error(err,true,line+1,13,filename);
				}
				if(_input_type(_getinput(in_i,0,i,cmd_argc,raw)) == 0)
					fprintf(ow,"4\n0\n%s\n",_getcontent(_getinput(in_i,0,i,cmd_argc,raw),line,filename));
				else if(_input_type(_getinput(in_i,0,i,cmd_argc,raw)) == 1)
					fprintf(ow,"4\n0\n%s\n",_getinput(in_i,0,i,cmd_argc,raw));
				else
					fprintf(ow,"4\n1\n%s\n",_getinput(in_i,0,i,cmd_argc,raw));
				fprintf(ow,"0\n%d\n",in_tmp-1);
				for(in_i2=1;in_i2<in_tmp;in_i2++)
				{
					if((_getinput(in_i,in_i2,i,cmd_argc,raw)[0] == '"') || (_getinput(in_i,in_i2,i,cmd_argc,raw)[0] == '\''))
						fprintf(ow,"0\n%s\n",_getcontent(_getinput(in_i,in_i2,i,cmd_argc,raw),line,filename));
					else
						fprintf(ow,"1\n%s\n",_getinput(in_i,in_i2,i,cmd_argc,raw));
				}
			}
		}
		else if(strcmp(cmd,"round") == 0)
		{
			// round/input,scale/output_var1,output_var2,...
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp == 0)
				_error("Number of inputs in the second argument must be at least 1",true,line+1,13,filename);
			fprintf(ow,"11\n2\n2\n%s\n%s\n%d\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(1,in_i2,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"while") == 0)
		{
			// while/![value operator value] gate [value operator value] ...
			fprintf(ow,"7\n%s",_process_if(raw,i,line,cmd_argc,filename));
		}
		else if(strcmp(cmd,"getletter") == 0)
		{
			// getletter/string,letter/output_var1,output_var2,...
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp == 0)
				_error("Number of inputs in the second argument must be at least 1",true,line+1,13,filename);
			fprintf(ow,"12\n2\n2\n%s\n%s\n%d\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(1,in_i2,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"getlength") == 0)
		{
			// getlength/string/output_var1,output_var2,...
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp == 0)
				_error("Number of inputs in the second argument must be at least 1",true,line+1,13,filename);
			fprintf(ow,"13\n2\n1\n%s\n%d\n",_getinput(0,0,i,cmd_argc,raw),in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(1,in_i2,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"setlist") == 0)
		{
			// setlist/list1_name,list2_name,...
			// setlist/list1_name,list2_name,.../item1,item2,...
			if((cmd_argc != 1) && (cmd_argc != 2))
				_error("Number of arguments must be 1 or 2",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			fprintf(ow,"14\n%d\n%d\n",cmd_argc,in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(0,in_i2,i,cmd_argc,raw));
			if(cmd_argc == 2)
			{
				in_tmp=_getinputc(1,i,cmd_argc,raw);
				fprintf(ow,"%d\n",in_tmp);
				for(in_i2=0;in_i2<in_tmp;in_i2++)
					fprintf(ow,"%s\n",_getinput(1,in_i2,i,cmd_argc,raw));
			}
		}
		else if(strcmp(cmd,"append") == 0)
		{
			// append/string/list_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"15\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"replace") == 0)
		{
			// replace/item,string/list_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"16\n2\n2\n%s\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"insert") == 0)
		{
			// insert/item,string/list_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"17\n2\n2\n%s\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"getitem") == 0)
		{
			// getitem/list_name,item/output_var1,output_var2,...
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp == 0)
				_error("Number of inputs in the second argument must be at least 1",true,line+1,13,filename);
			fprintf(ow,"18\n2\n2\n%s\n%s\n%d\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(1,in_i2,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"getlistlength") == 0)
		{
			// getlistlength/list_name/output_var1,output_var2,...
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp == 0)
				_error("Number of inputs in the second argument must be at least 1",true,line+1,13,filename);
			fprintf(ow,"19\n2\n1\n%s\n%d\n",_getinput(0,0,i,cmd_argc,raw),in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(1,in_i2,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"define") == 0)
		{
			// define/function_name
			if(_def)
				_error("Can't define sub-function",true,line+1,14,filename);
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			_def=true;
			_def_started=false;
			func_type=1;
			strcpy(func_name,_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
		}
		else if(strcmp(cmd,"linkdef") == 0)
		{
			// linkdef/function_name
			// linkdef/function_name,function_var_name
			// linkdef/function_name,function_var_name,type
			// Types: local, global
			if(_def)
				_error("Can't define sub-function",true,line+1,14,filename);
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if((_getinputc(0,i,cmd_argc,raw) != 1) && (_getinputc(0,i,cmd_argc,raw) != 2) && (_getinputc(0,i,cmd_argc,raw) != 3))
				_error("Number of inputs in the first argument must be 1, 2 or 3",true,line+1,13,filename);
			_def=true;
			_def_started=false;
			func_type=2;
			strcpy(func_name,_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
			if(_getinputc(0,i,cmd_argc,raw) == 1)
			{
				strcpy(linkdef_var_name,func_name);
				linkdef_type=1; // local by default
			}
			else
			{
				strcpy(linkdef_var_name,_getcontent(_getinput(0,1,i,cmd_argc,raw),line,filename));
				if(_getinputc(0,i,cmd_argc,raw) == 3)
				{
					if(strcmp(_getcontent(_getinput(0,2,i,cmd_argc,raw),line,filename),"local") == 0)
						linkdef_type=1;
					else if(strcmp(_getcontent(_getinput(0,2,i,cmd_argc,raw),line,filename),"global") == 0)
						linkdef_type=2;
					else
					{
						sprintf(err,"Unknown linkdef type: '%s'",_getcontent(_getinput(0,2,i,cmd_argc,raw),line,filename));
						_error(err,true,line+1,14,filename);
					}
				}
				else
					linkdef_type=1; // local by default
			}
		}
		else if(strcmp(cmd,"{") == 0)
		{
			if((!(_def)) || (_def && _def_started))
				_error("Unexpected token '{'",true,line+1,14,filename);
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fclose(ow);
			if(func_type == 1)
				sprintf(part,".functions/%s",func_name);
			else if(func_type == 2)
				sprintf(part,".functions/%s.tmp",func_name);
			ow = fopen(part,"w");
			_def_started=true;
		}
		else if((_def) && (!(_def_started)))
			_error("Expected token '{' but got a function",true,line+1,14,filename);
		else if(strcmp(cmd,"}") == 0)
		{
			if(!(_def))
				_error("Unexpected token '}'",true,line+1,14,filename);
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fclose(ow);
			if(func_type == 2)
			{
				sprintf(part,".functions/%s",func_name);
				sprintf(part3,".functions/%s.tmp",func_name);
				ow = fopen(outfn,"a");
				fprintf(ow,">>\n");
				if(linkdef_type == 2)
					putc('$',ow);
				fprintf(ow,"tmp_lib_%s\n",linkdef_var_name);
				fclose(ow);
				endstrconv(part3,outfn,"a");
				ow = fopen(outfn,"a");
				putc('\n',ow);
				fclose(ow);
				remove(part3);
				ow = fopen(part,"w");
				fprintf(ow,"L\n");
				if(linkdef_type == 2)
					putc('$',ow);
				fprintf(ow,"tmp_lib_%s\n",linkdef_var_name);
				fclose(ow);
			}
			ow = fopen(outfn,"a");
			_def=false;
			_def_started=false;
		}
		else if(strcmp(cmd,"run") == 0)
		{
			// run/executable_code,wait_or_bg,start_byte,size/[arg1]/[arg2]/...
			if(cmd_argc == 0)
				_error("Number of arguments must be at least 1",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			if((in_tmp < 1) || (in_tmp > 4))
				_error("Number of inputs in the first argument must be 1, 2, 3 or 4",true,line+1,13,filename);
			fprintf(ow,"1A\n%d\n%d\n",cmd_argc,in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(0,in_i2,i,cmd_argc,raw));
			for(in_i2=1;in_i2<cmd_argc;in_i2++)
			{
				fprintf(ow,"%d\n",_getinputc(in_i2,i,cmd_argc,raw));
				for(in_tmp=0; in_tmp < _getinputc(in_i2,i,cmd_argc,raw); in_tmp++)
					fprintf(ow,"%s\n",_getinput(in_i2,in_tmp,i,cmd_argc,raw));
			}
		}
		else if(strcmp(cmd,"source") == 0)
		{
			// source/executable_code,wait_or_bg/[arg1]/[arg2]/...
			if(cmd_argc == 0)
				_error("Number of arguments must be at least 1",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			if((in_tmp != 1) && (in_tmp != 2))
				_error("Number of inputs in the first argument must be 1 or 2",true,line+1,13,filename);
			fprintf(ow,"1B\n%d\n%d\n",cmd_argc,in_tmp);
			for(in_i2=0;in_i2<in_tmp;in_i2++)
				fprintf(ow,"%s\n",_getinput(0,in_i2,i,cmd_argc,raw));
			for(in_i2=1;in_i2<cmd_argc;in_i2++)
			{
				fprintf(ow,"%d\n",_getinputc(in_i2,i,cmd_argc,raw));
				for(in_tmp=0; in_tmp < _getinputc(in_i2,i,cmd_argc,raw); in_tmp++)
					fprintf(ow,"%s\n",_getinput(in_i2,in_tmp,i,cmd_argc,raw));
			}
		}
		else if(strcmp(cmd,"getkey") == 0)
		{
			// getkey/output_list_name
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"1C\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"bgcolor") == 0)
		{
			// bgcolor/color
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_input_type(_getinput(0,0,i,cmd_argc,raw)) == 0)
				fprintf(ow,"m4\n0\n%s\n",_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
			else if(_input_type(_getinput(0,0,i,cmd_argc,raw)) == 1)
				fprintf(ow,"m4\n0\n%s\n",_getinput(0,0,i,cmd_argc,raw));
			else
				fprintf(ow,"m4\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"warp") == 0)
		{
			// warp
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"1E\n0\n");
		}
		else if(strcmp(cmd,"endwarp") == 0)
		{
			// endwarp
			if(cmd_argc > 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"1F\n0\n");
		}
		else if(strcmp(cmd,"wait") == 0)
		{
			// wait/time_in_seconds
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"20\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"listdisk") == 0)
		{
			// listdisk/output_list_name
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"22\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"createdisk") == 0)
		{
			// createdisk/disk_name,size_in_bytes
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			fprintf(ow,"23\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"rmdisk") == 0)
		{
			// rmdisk/disk_name
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"24\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"renamedisk") == 0)
		{
			// renamedisk/disk_ID,new_disk_name
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			fprintf(ow,"25\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"beep") == 0)
		{
			// beep/frequency,duration_in_seconds
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			fprintf(ow,"26\n1\n2\n%s\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"deleteitem") == 0)
		{
			// deleteitem/item/list_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"27\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"getdisksize") == 0)
		{
			// getdisksize/disk_ID/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"28\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"showlogo") == 0)
		{
			// showlogo
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"m5\n0\n0\n0\n1\n");
		}
		else if(strcmp(cmd,"hidelogo") == 0)
		{
			// hidelogo
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"m5\n0\n0\n0\n0\n");
		}
		else if(strcmp(cmd,"enabletext") == 0)
		{
			// enabletext
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"m5\n0\n1\n0\n1\n");
		}
		else if(strcmp(cmd,"disabletext") == 0)
		{
			// disabletext
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"m5\n0\n1\n0\n0\n");
		}
		else if(strcmp(cmd,"shutdown") == 0)
		{
			// shutdown
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"2B\n1\n1\n1\n");
		}
		else if(strcmp(cmd,"reboot") == 0)
		{
			// reboot
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"2B\n1\n1\n2\n");
		}
		else if(strcmp(cmd,"writedisk") == 0)
		{
			// writedisk/byte/disk_ID,byte_ID
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the second argument must be 2",true,line+1,13,filename);
			fprintf(ow,"2C\n2\n1\n%s\n2\n%s\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw),_getinput(1,1,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"loadcode") == 0)
		{
			// loadcode/code
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"2D\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"leavebios") == 0)
		{
			// leavebios
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"2E\n0\n");
		}
		else if(strcmp(cmd,"readdisk") == 0)
		{
			// readdisk/disk_ID,byte_ID/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"2E\n2\n2\n%s\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"print>") == 0)
		{
			// print>
			// print>/color
			// text
			// text,\n,text
			// ...
			// <print
			if((cmd_argc != 0) && (cmd_argc != 1))
				_error("Number of arguments must be 0 or 1",true,line+1,12,filename);
			if(cmd_argc == 1)
			{
				if(_getinputc(0,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
				col2=1;
				fprintf(ow,"21\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
			}
			else
				col2=0;
		}
		else if(strcmp(cmd,"<print") == 0)
		{
			// <print
			// This function doesn't need checks (see the "Exception for print>" comment above)
			if(col2 == 1)
				fprintf(ow,"21\n1\n1\n255255255\n");
		}
		else if(strcmp(cmd,"showcplist") == 0)
		{
			// showcplist/list_name
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"30\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"hidecplist") == 0)
		{
			// hidecplist
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"31\n0\n");
		}
		else if(strcmp(cmd,"cpdisk") == 0)
		{
			// cpdisk/disk_ID,0_1_or_2_(full__exclude_MBR__MBR_only)/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if((_getinputc(0,i,cmd_argc,raw) != 1) && (_getinputc(0,i,cmd_argc,raw) != 2))
				_error("Number of inputs in the first argument must be 1 or 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			if(_getinputc(0,i,cmd_argc,raw) == 1)
				fprintf(ow,"32\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
			else
				fprintf(ow,"32\n2\n2\n%s\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"bintolist") == 0)
		{
			// bintolist/string/output_list_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"33\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"listtobin") == 0)
		{
			// listtobin/list_name/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"34\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"readvar") == 0)
		{
			// readvar/var_name/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"35\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"getindex") == 0)
		{
			// getindex/list_name,string/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"36\n2\n2\n%s\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"smc_getarg") == 0)
		{
			// smc_getarg/input_list_name,index,var_names_list,var_values_list,global_var_names_list,global_var_values_list/index2_var_name,command_list_name,argument_lists_prefix
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			if(in_tmp != 6)
				_error("Number of inputs in the first argument must be 6",true,line+1,13,filename);
			fprintf(ow,"37\n2\n%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(0,in_i,i,cmd_argc,raw));
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp != 3)
				_error("Number of inputs in the second argument must be 3",true,line+1,13,filename);
			fprintf(ow,"%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(1,in_i,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"add") == 0)
		{
			// add/num1,num2/output_var
			// add/num1,num2/output_var/scale
			if((cmd_argc != 2) && (cmd_argc != 3))
				_error("Number of arguments must be 2 or 3",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"F\n%d\n1\n1\n1\n%s\n2\n%s\n%s\n",cmd_argc+1,_getinput(1,0,i,cmd_argc,raw),_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
			if(cmd_argc == 3)
			{
				if(_getinputc(1,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the third argument must be 1",true,line+1,13,filename);
				fprintf(ow,"1\n%s\n",_getinput(2,0,i,cmd_argc,raw));
			}
			
		}
		else if(strcmp(cmd,"sub") == 0)
		{
			// sub/num1,num2/output_var
			// sub/num1,num2/output_var/scale
			if((cmd_argc != 2) && (cmd_argc != 3))
				_error("Number of arguments must be 2 or 3",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"F\n%d\n1\n2\n1\n%s\n2\n%s\n%s\n",cmd_argc+1,_getinput(1,0,i,cmd_argc,raw),_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
			if(cmd_argc == 3)
			{
				if(_getinputc(1,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the third argument must be 1",true,line+1,13,filename);
				fprintf(ow,"1\n%s\n",_getinput(2,0,i,cmd_argc,raw));
			}
			
		}
		else if(strcmp(cmd,"multi") == 0)
		{
			// multi/num1,num2/output_var
			// multi/num1,num2/output_var/scale
			if((cmd_argc != 2) && (cmd_argc != 3))
				_error("Number of arguments must be 2 or 3",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"F\n%d\n1\n3\n1\n%s\n2\n%s\n%s\n",cmd_argc+1,_getinput(1,0,i,cmd_argc,raw),_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
			if(cmd_argc == 3)
			{
				if(_getinputc(1,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the third argument must be 1",true,line+1,13,filename);
				fprintf(ow,"1\n%s\n",_getinput(2,0,i,cmd_argc,raw));
			}
			
		}
		else if(strcmp(cmd,"div") == 0)
		{
			// div/num1,num2/output_var
			// div/num1,num2/output_var/scale
			if((cmd_argc != 2) && (cmd_argc != 3))
				_error("Number of arguments must be 2 or 3",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"F\n%d\n1\n4\n1\n%s\n2\n%s\n%s\n",cmd_argc+1,_getinput(1,0,i,cmd_argc,raw),_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
			if(cmd_argc == 3)
			{
				if(_getinputc(1,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the third argument must be 1",true,line+1,13,filename);
				fprintf(ow,"1\n%s\n",_getinput(2,0,i,cmd_argc,raw));
			}
			
		}
		else if(strcmp(cmd,"mod") == 0)
		{
			// mod/num1,num2/output_var
			// mod/num1,num2/output_var/scale
			if((cmd_argc != 2) && (cmd_argc != 3))
				_error("Number of arguments must be 2 or 3",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"F\n%d\n1\n5\n1\n%s\n2\n%s\n%s\n",cmd_argc+1,_getinput(1,0,i,cmd_argc,raw),_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw));
			if(cmd_argc == 3)
			{
				if(_getinputc(1,i,cmd_argc,raw) != 1)
					_error("Number of inputs in the third argument must be 1",true,line+1,13,filename);
				fprintf(ow,"1\n%s\n",_getinput(2,0,i,cmd_argc,raw));
			}
			
		}
		else if(strcmp(cmd,"abs") == 0)
		{
			// abs/input/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"38\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"include") == 0)
		{
			// include/path
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			sprintf(part4,"%s/%s",include_dir,_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
			strcpy(part3,part4);
			strcat(part3,".include");
			errno=0;
			funcr = fopen(part4,"r");
			if(errno != 0)
			{
				strcat(err,part4);
				strcat(err,": ");
				strcat(err,strerror(errno));
				_error(err,true,line+1,18,filename);
			}
			fclose(funcr);
			sprintf(part,"%s %s/%s --include -o ",argv[0],include_dir,_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
			strcat(part,part3);
			strcat(part," --include-dir ");
			strcat(part,include_dir);
			if(system(part) != 0)
			{
				strcpy(err,"Failed to include ");
				strcat(err,_getcontent(_getinput(0,0,i,cmd_argc,raw),line,filename));
				_error(err,true,line+1,18,filename);
			}
			funcr = fopen(part3,"r");
			while((c=getc(funcr)) != EOF)
				putc(c,ow);
			fclose(funcr);
			remove(part3);
		}
		else if(strcmp(cmd,"getletterindex") == 0)
		{
			// getletterindex/string,char/output_var
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 2)
				_error("Number of inputs in the first argument must be 2",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"39\n2\n2\n%s\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(0,1,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"replacedisk") == 0)
		{
			// replacedisk/string/disk_ID
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			if(_getinputc(1,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the second argument must be 1",true,line+1,13,filename);
			fprintf(ow,"3A\n2\n1\n%s\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw),_getinput(1,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"insmedia") == 0)
		{
			// insmedia/string
			if(cmd_argc != 1)
				_error("Number of arguments must be 1",true,line+1,12,filename);
			if(_getinputc(0,i,cmd_argc,raw) != 1)
				_error("Number of inputs in the first argument must be 1",true,line+1,13,filename);
			fprintf(ow,"3B\n1\n1\n%s\n",_getinput(0,0,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"smc_skiploop") == 0)
		{
			// smc_skiploop/input_list_name,index,var_names_list,var_values_list,global_var_names_list,global_var_values_list/index2_var_name,command_list_name,argument_lists_prefix,reserved_var_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			if(in_tmp != 6)
				_error("Number of inputs in the first argument must be 6",true,line+1,13,filename);
			fprintf(ow,"3C\n2\n%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(0,in_i,i,cmd_argc,raw));
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp != 4)
				_error("Number of inputs in the second argument must be 4",true,line+1,13,filename);
			fprintf(ow,"%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(1,in_i,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"smc_skipif") == 0)
		{
			// smc_skipif/input_list_name,index,var_names_list,var_values_list,global_var_names_list,global_var_values_list/index2_var_name,command_list_name,argument_lists_prefix,reserved_var_name
			if(cmd_argc != 2)
				_error("Number of arguments must be 2",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			if(in_tmp != 6)
				_error("Number of inputs in the first argument must be 6",true,line+1,13,filename);
			fprintf(ow,"3D\n2\n%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(0,in_i,i,cmd_argc,raw));
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp != 4)
				_error("Number of inputs in the second argument must be 4",true,line+1,13,filename);
			fprintf(ow,"%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(1,in_i,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"smc_if") == 0)
		{
			// smc_if/global_(1_or_0),global_custom_ID/input_list_name,index,var_names_list,var_values_list,global_var_names_list,global_var_values_list/index2_var_name,command_list_name,argument_lists_prefix,reserved_var_name,gate_output_var_name
			if(cmd_argc != 3)
				_error("Number of arguments must be 3",true,line+1,12,filename);
			in_tmp=_getinputc(0,i,cmd_argc,raw);
			if((in_tmp != 1) && (in_tmp != 2))
				_error("Number of inputs in the first argument must be 1 or 2",true,line+1,13,filename);
			fprintf(ow,"3E\n3\n%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(0,in_i,i,cmd_argc,raw));
			in_tmp=_getinputc(1,i,cmd_argc,raw);
			if(in_tmp != 6)
				_error("Number of inputs in the second argument must be 6",true,line+1,13,filename);
			fprintf(ow,"%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(1,in_i,i,cmd_argc,raw));
			in_tmp=_getinputc(2,i,cmd_argc,raw);
			if(in_tmp != 5)
				_error("Number of inputs in the second argument must be 5",true,line+1,13,filename);
			fprintf(ow,"%d\n",in_tmp);
			for(in_i=0;in_i<in_tmp;in_i++)
				fprintf(ow,"%s\n",_getinput(2,in_i,i,cmd_argc,raw));
		}
		else if(strcmp(cmd,"deletechar") == 0)
		{
			// deletechar
			if(cmd_argc != 0)
				_error("Number of arguments must be 0",true,line+1,12,filename);
			fprintf(ow,"3F\n0\n");
		}
		else
		{
			sprintf(err,"Function '%s' not found",cmd);
			_error(err,true,line+1,11,filename);
		}
		// Skip args
		for(argn=0;argn<cmd_argc;argn++)
		{
			// Get input count
			strcpy(part2,"");
			while(raw[i] != '\n')
			{
				strncat(part2,&raw[i],1);
				i++;
			}
			arg_inputc=strtol(part2,NULL,10);
			i++;
			// Skip inputs
			for(inputn=0;inputn<arg_inputc;inputn++)
			{
				while(raw[i] != '\n')
				{
					i++;
				}
				i++;
			}
		}
	}
	if(_def)
		_error("Unexpected end of file while searching for function end",false,0,2,filename);
	fclose(fr);
	fclose(ow);
	if(strconv)
	{
		endstrconv(outfn,".tmp","w");
		ow = fopen(outfn,"w");
		FILE *ar = fopen(".tmp","r");
		while((c=getc(ar)) != EOF)
			putc(c,ow);
		fclose(ow);
		fclose(ar);
		remove(".tmp");
	}
	free(raw);
	if(!(forceinclude))
		system("rm -rf .functions");
	return 0;
}
