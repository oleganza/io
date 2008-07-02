
Notifier := Object clone do(
	addListener := method(listener,
		if(self getSlot("listeners") == nil, self listeners := List clone)
		listeners append(listener);
		self
	)

	removeListener := method(obj,
		if(?listeners, listeners remove(obj))
	)

	notifyListeners := method(
		if(?listeners,
			listeners foreach(l,
				if(l hasSlot(call argAt(0) name),
					stopStatus(l doMessage(call argAt(0), call sender))
				)
			)
		)
	)
)

FutureProxy := Object clone do(
	with := method(future,
		p := self clone
		p _future := future
		p forward := self getSlot("_forward")
		p _become := self getSlot("become")
		//p xyz := method(_future writeln("XYZ!"))
		p type := "FutureProxy"
		p removeAllProtos
		p
	)

	_forward := method(
		//_future writeln("FutureProxy forward ", call message)
		_future waitOnResult
		self doMessage(call message, call sender)
	)
)

Future := Object clone do(
	newSlot("runTarget")
	newSlot("runMessage")
	newSlot("runSender")
	newSlot("waitingCoros")

	futureProxy := method(
		self waitingCoros := List clone
		self proxy := FutureProxy with(self)
		proxy
	)

	setResult := method(r,
		if(self hasSlot("proxy"),
			proxy _become(getSlot("r"))
			if(waitingCoros, waitingCoros foreach(resumeLater))
			//notifyListeners(futureReady(self))
		)
	)

	waitOnResult := method(
		waitingCoros append(Scheduler currentCoroutine)
		Scheduler currentCoroutine pause
	)
)

/*
Object do(
	actorIsRunning := method(
		//writeln("self hasLocalSlot(actorCoroutine) = ", self hasLocalSlot("actorCoroutine"))
		if(self hasLocalSlot("actorCoroutine"),
			writeln("actorQueue size = ", actorQueue size)
			writeln("Coroutine yieldingCoros contains(actorCoroutine) = ", Coroutine yieldingCoros contains(actorCoroutine))
			writeln("Coroutine currentCoroutine == actorCoroutine = ", Coroutine currentCoroutine == actorCoroutine)
		)

		self hasLocalSlot("actorCoroutine") and(actorQueue size > 0) and(
			Coroutine yieldingCoros contains(actorCoroutine) or(Coroutine currentCoroutine == actorCoroutine)
		)
	)
	actorIsPaused := method(self hasLocalSlot("actorCoroutine") and(actorQueue size > 0))
	actorPause := method(if(actorIsPaused, actorCoroutine pause))
	actorResume := method(if(actorIsPaused, actorCoroutine resumeLater))
)
*/

Object do(
	yield := method(Coroutine currentCoroutine yield)
	pause := method(Coroutine currentCoroutine pause)

	actorRun := method(
		if(self hasLocalSlot("actorCoroutine"),
			if(actorQueue size == 0, self actorCoroutine resumeLater)
		,
			self actorQueue := List clone
			// need to yield in coroDo to allow future to be added to queue
			//self actorCoroutine := self coroDo(yield; actorProcessQueue) // coroDo refs stack!
			self actorCoroutine := Coroutine clone //setStackSize(20000)
			actorCoroutine setRunTarget(self)
			actorCoroutine setRunLocals(self)
			actorCoroutine setRunMessage(message(actorProcessQueue))
			Coroutine yieldingCoros atInsert(0, actorCoroutine)
			//Coroutine yieldingCoros append(actorCoroutine)
		)
	)

	actorProcessQueue := method(
		//writeln(self type, "_", self uniqueId, " actorProcessQueue")

		/*
		if(Coroutine currentCoroutine isIdenticalTo(self actorCoroutine) not,
			writeln("actorProcessQueue called from coro ", Coroutine currentCoroutine uniqueId, " instead of ", actorCoroutine uniqueId)
			System exit
		)
		*/

		loop(
			while(future := actorQueue first,
				e := try(
					future setResult(future runMessage doInContext(self, future runSender))
					//stopStatus(future setResult(self doMessage(future runMessage)))
				)
				actorQueue removeFirst
				if(e, handleActorException(e))
				if(actorQueue first, yield)
			)

/*
			if(Coroutine currentCoroutine isIdenticalTo(self actorCoroutine) not,
				writeln("actorProcessQueue1 called from coro ", Coroutine currentCoroutine uniqueId, " instead of ", self actorCoroutine uniqueId)
				System exit
			)
*/
			self actorCoroutine pause
		)
	)

	handleActorException := method(e, e showStack)

	setSlot("@", method(
		//writeln("@ ", call argAt(0))
		m := call argAt(0)
		f := Future clone setRunTarget(self) setRunMessage(m) setRunSender(call sender)
		self actorRun
		self actorQueue append(f)
		f futureProxy
	))

	setSlot("@@", method(
		//writeln(self type , "_", self uniqueId, " @@", call argAt(0)) //, " ", call argAt(0) label)
		m := call argAt(0)
		f := Future clone setRunTarget(self) setRunMessage(m) setRunSender(call sender)
		self actorRun
		self actorQueue append(f)
		nil
	))
)

