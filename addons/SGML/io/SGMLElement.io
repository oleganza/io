Sequence writeToStream := method(b, b appendSeq(self))

SGMLElement := Object clone do(
	//metadoc SGMLElement Representation of an SGML / HTML / XML tag.
	//doc SGMLElement setName(aString) Sets the tag name. Returns self.
	//doc SGMLElement name Returns the tag name
	//doc SGMLElement attributes Returns a Map containing the tag's attributes.
	//doc SGMLElement subitems Returns a List containing the tag's subitems.
	//doc SGMLElement asString Returns a String representation of the tag and all of it's subitems.

	newSlot("name")
	newSlot("attributes", Map clone)
	newSlot("subitems", List clone)
	newSlot("text")
	newSlot("parent")

	withText := method(text,
		self clone setText(text)
	)

	init := method(
		self attributes := attributes clone
		self subitems := subitems clone
	)

	asString := method(
		b := Sequence clone
		writeToStream(b)
		b asString
	)

	writeToStream := method(b,
		if(name, beginTag(b), if(text, b appendSeq(text)))
		subitems foreach(writeToStream(b))
		if(name, endTag(b))
	)

	beginTag := method(b,
		if(b == nil, b := Sequence clone)
		if(name,
			b appendSeq("<", name)
			attributes keys sort foreach(k,
				v := attributes at(k)
				b appendSeq(" ", k, "=\"", v, "\"")
			)
			b appendSeq(">")
		)
		b
	)

	endTag := method(b,
		if(b == nil, b := Sequence clone)
		b appendSeq("</", name, ">")
		b
	)

	// extras

	elementWithName := method(name,
		if(name == self name, return self)
		subitems detect(elementWithName(name)) returnIfNonNil
		nil
	)

	elementsWithName := method(name, list,
		if(list == nil, list := List clone)
		if(name == self name, list append(self))
		subitems foreach(elementsWithName(name, list))
		list
	)

	asObject := method(prefix,
		if(prefix == nil, prefix = "XML")
		if(text, return text)
		if(subitems size == 1 and subitems first text, return subitems first text)

		p := getSlot(prefix .. name ?asCapitalized)
		obj := if(p, p clone, Object clone)

		subitems foreach(v,
			if(v text, continue)
			k := v name
			while(k containsSeq(":"), k = k afterSeq(":"))
			k = k asMutable replaceSeq("?", "")
			plural := k .. "s"
			ev := obj getLocalSlot(k)
			if(ev) then(
				l := obj getLocalSlot(plural)
				if(l == nil, l := obj setSlot(plural, List clone append(ev)))
				l append(v asObject)
			) else(
				obj setSlot(k, v asObject)
			)
		)
		obj
	)

	redirectStrings := method(
		redirects := self elementsWithName("meta")
		redirects selectInPlace(attributes at("content"))
		redirects mapInPlace(attributes at("content") afterSeq("URL="))
		redirects selectInPlace(!= nil)
	)

	linkStrings := method(
		self elementsWithName("a") mapInPlace(attributes at("href"))
	)

	search := method(b, list,
		if(list == nil, list := List clone)
		if(b(self), list append(self))
		subitems foreach(item, item setParent(self))
		subitems foreach(item, item search(getSlot("b"), list))
		list
	)

	tableData := method(
		elementsWithName("tr") map(search(block(e, e name == "td" or e name == "th")) map(subitems first ?text))
	)
)


SGMLParser do(
	elementProto := SGMLElement

	init := method(
		self stack := List clone
		self root := elementProto clone
		stack push(root)
	)

	top := method(
		if(stack last, stack last, root)
	)

	startElement := method(name,
		e := elementProto clone setName(name)
		top subitems append(e)
		e setParent(top)
		stack push(e)
	)

	endElement := method(name,
		stack pop
	)

	newAttribute := method(k, v,
		top attributes atPut(k, v)
	)

	newText := method(text,
		//top subitems append(text)
		top subitems append(elementProto withText(text))
	)

	elementForString := method(aString,
		parse(aString)
		root
	)
)

Sequence do(
	//doc Sequence asHTML SGML extension to interpret the Sequence as HTML and return an SGML object using SGMLParser elementForString
	asHTML := method(SGMLParser clone elementForString(self))
	//doc Sequence asXML SGML extension to interpret the Sequence as XML and return an SGML object using SGMLParser elementForString
	asXML  := method(SGMLParser clone elementForString(self))
	//doc Sequence asSGML SGML extension to interpret the Sequence as SGML and return an SGML object using SGMLParser elementForString
	asSGML := method(SGMLParser clone elementForString(self))
)

SGML := Object clone do(
	SGMLElement := SGMLElement
	SGMLParser := SGMLParser
)

