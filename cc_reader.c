/* Copyright (C) 2016 Jeremiah Orians
 * This file is part of M2-Planet.
 *
 * M2-Planet is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * M2-Planet is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with M2-Planet.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "cc.h"
FILE* input;
struct token_list* token;
int line;
char* file;
int in_set(int c, char* s);

int clearWhiteSpace(int c)
{
	if((32 == c) || (9 == c)) return clearWhiteSpace(fgetc(input));
	else if (10 == c)
	{
		line = line + 1;
		return clearWhiteSpace(fgetc(input));
	}
	return c;
}

int consume_byte(int c)
{
	hold_string[string_index] = c;
	string_index = string_index + 1;
	return fgetc(input);
}

int preserve_string(int c)
{
	int frequent = c;
	int escape = FALSE;
	do
	{
		if(!escape && '\\' == c ) escape = TRUE;
		else escape = FALSE;
		c = consume_byte(c);
	} while(escape || (c != frequent));
	return fgetc(input);
}

 void fixup_label()
{
	int hold = ':';
	int prev;
	int i = 0;
	do
	{
		prev = hold;
		hold = hold_string[i];
		hold_string[i] = prev;
		i = i + 1;
	} while(0 != hold);
}

int preserve_keyword(int c, char* S)
{
	while(in_set(c, S))
	{
		c = consume_byte(c);
	}
	return c;
}

int purge_macro(int ch)
{
	while(10 != ch) ch = fgetc(input);
	return ch;
}

void reset_hold_string()
{
	int i = string_index + 2;
	while(0 != i)
	{
		hold_string[i] = 0;
		i = i - 1;
	}
}

int get_token(int c)
{
	struct token_list* current = calloc(1, sizeof(struct token_list));

reset:
	reset_hold_string();
	string_index = 0;

	c = clearWhiteSpace(c);
	if(c == EOF)
	{
		free(current);
		return c;
	}
	else if('#' == c)
	{
		c = purge_macro(c);
		goto reset;
	}
	else if(in_set(c, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"))
	{
		c = preserve_keyword(c, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_");
		if(':' == c)
		{
			fixup_label();
			c = ' ';
		}
	}
	else if(in_set(c, "<=>|&!-"))
	{
		c = preserve_keyword(c, "<=>|&!-");
	}
	else if(in_set(c, "'\""))
	{
		c = preserve_string(c);
	}
	else if(c == '/')
	{
		c = consume_byte(c);
		if(c == '*')
		{
			c = fgetc(input);
			while(c != '/')
			{
				while(c != '*')
				{
					c = fgetc(input);
					if(10 == c) line = line + 1;
				}
				c = fgetc(input);
				if(10 == c) line = line + 1;
			}
			c = fgetc(input);
			goto reset;
		}
		else if(c == '/')
		{
			c = fgetc(input);
			goto reset;
		}
	}
	else
	{
		c = consume_byte(c);
	}

	/* More efficiently allocate memory for string */
	current->s = calloc(string_index + 2, sizeof(char));
	copy_string(current->s, hold_string);

	current->prev = token;
	current->next = token;
	current->linenumber = line;
	current->filename = file;
	token = current;
	return c;
}

struct token_list* reverse_list(struct token_list* head)
{
	struct token_list* root = NULL;
	while(NULL != head)
	{
		struct token_list* next = head->next;
		head->next = root;
		root = head;
		head = next;
	}
	return root;
}

struct token_list* read_all_tokens(FILE* a, struct token_list* current, char* filename)
{
	input  = a;
	line = 1;
	file = filename;
	token = current;
	int ch =fgetc(input);
	while(EOF != ch) ch = get_token(ch);

	return token;
}
