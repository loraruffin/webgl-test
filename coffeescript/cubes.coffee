

class Space
    constructor: (@container) ->
        @last_time = null
        @objects = []

        @scene = new THREE.Scene
        @renderer = new THREE.WebGLRenderer
        @renderer.setSize(@container.offsetWidth, @container.offsetHeight)
        @renderer.shadowMapEnabled = true
        @renderer.shadowMapSoft = true
        #@renderer.setClearColor 0x0099FF, 1
        @container.appendChild( @renderer.domElement )
        @camera = new THREE.PerspectiveCamera(45, @container.offsetWidth / @container.offsetHeight, 1, 4000 )
        @camera.position.set  0, 5, 0
        window.addEventListener 'resize', => @onWindowResize()
        @start_stats()


    addToScene: (o) ->
        @scene.add o


    addLight: (x, y, z, color, intensity, castShadow = false) ->
        light = new THREE.DirectionalLight color, intensity
        light.position.set x, y, z
        if castShadow
            light.castShadow = true
            light.shadowCameraNear = 0.01
            #light.shadowCameraVisible = true
            light.shadowMapWidth = 2048
            light.shadowMapHeight = 2048
            d = 10
            light.shadowCameraLeft = -d
            light.shadowCameraRight = d
            light.shadowCameraTop = d
            light.shadowCameraBottom = -d

            light.shadowCameraFar = 100
            light.shadowDarkness = 0.5
        @addToScene light


    onWindowResize: ->
        if @isFullscreen
            w = window.innerWidth
            h = window.innerHeight
        else
            w = @container.offsetWidth
            h = @container.offsetHeight
        @renderer.setSize(w, h)
        @camera.aspect = w / h
        @camera.updateProjectionMatrix()
        


    start_stats: ->
        @stats = new Stats
        #@stats.setMode(1) // 0: fps, 1: ms
        @stats.domElement.style.position = 'absolute'
        @stats.domElement.style.left = '0px'
        @stats.domElement.style.top = '0px'
        document.body.appendChild @stats.domElement


    update: (t_step, timestamp) ->
        sin_speed = timestamp / 1000 / 5
        @camera.position.x = Math.sin(sin_speed + Math.PI / 2) * 10
        @camera.position.z = Math.sin(sin_speed) * 10
        @camera.lookAt(new THREE.Vector3(0,0,0))
        for o in @objects
            o.update(t_step, timestamp)


    run: (timestamp) ->
        @last_time = timestamp unless @last_time
        t_step = timestamp - @last_time
        if t_step > 0
            @update(t_step, timestamp)
            @render()
            @last_time = timestamp
            @stats.update()
        else
            @render()
        requestAnimationFrame (par) => @run par


    add: (obj) ->
        @scene.add obj.object3D 
        @objects.push obj

    render: ->
        @renderer.render @scene, @camera


class Object3D
    update: (t_step, timestamp) ->


    setPosition: (pos) ->
        @setPos = pos
        @object3D.position.x = pos[0]
        @object3D.position.y = pos[1]
        @object3D.position.z = pos[2]
        @


class Cube extends Object3D
    constructor: (@space) ->
        materials = @makeMaterials()
        material = new THREE.MeshFaceMaterial( materials )
        #material = new THREE.MeshLambertMaterial({color: 0x0aeedf})
        geometry = new THREE.CubeGeometry(1, 1, 1)
        @object3D = new THREE.Mesh(geometry, material)
        @object3D.castShadow = true
        @object3D.receiveShadow = true
        @rotStart = Math.PI * Math.random()


    makeTextureDraw: (text) ->
        bitmap = document.createElement('canvas')
        g = bitmap.getContext('2d')
        bitmap.width = 100
        bitmap.height = 100
        g.fillStyle = '#404040'
        g.fillRect(0,0,bitmap.width,bitmap.height)
        g.fillStyle = '#FFFFFF'
        g.fillRect(10,10,80,80)
        
        #g.fillRect(0, 0, bitmap.width, bitmap.height)
        g.font = 'Bold 80px Arial'
        g.fillStyle = '#202020'
        g.textBaseline = 'middle'
        g.textAlign = 'center'
        g.fillText(text, bitmap.width / 2, bitmap.height / 2)
        bitmap


    makeMaterials: ->
        for i in [0..5]
            texture = new THREE.Texture (@makeTextureDraw i.toString())
            texture.needsUpdate = true
            texture.anisotropy = @space.renderer.getMaxAnisotropy()
            new THREE.MeshLambertMaterial map: texture


    setRotations: (rot) ->
        [@rotXspeed, @rotYspeed, @rotZspeed] = rot
        @

    update: (t_step, timestamp) ->
        step = t_step / 16.7
        sin_step = timestamp / 1000 * 1.5
        if @rotXspeed != 0
            @object3D.rotation.x -= step * @rotXspeed
            @object3D.position.x = @setPos[0] + Math.sin(sin_step + @rotStart)
        if @rotYspeed != 0
            @object3D.rotation.y -= step * @rotYspeed
            @object3D.position.y = @setPos[1] + Math.sin(sin_step + @rotStart)
        if @rotZspeed != 0
            @object3D.rotation.z -= step * @rotZspeed
            @object3D.position.z = @setPos[2] + Math.sin(sin_step + @rotStart)


makeGrid = ({spacing, count, centered}) ->
    spacing ?= new THREE.Vector3(1, 1, 1)
    count ?= new THREE.Vector3(1, 1, 1)
    centered ?= true
    center = new THREE.Vector3(0, 0, 0)
    result = []
    if centered
        center.multiplyVectors spacing, (new THREE.Vector3()).subVectors(count, new THREE.Vector3(1, 1, 1))
        center.divide (new THREE.Vector3(2, 2, 2))
    for x in [0...count.x]
        for y in [0...count.y]
            for z in [0...count.z]
                result.push [x * spacing.x - center.x, y * spacing.y - center.y, z * spacing.z - center.z]
    result


makeCombinations = (size) ->
    for x in [0...Math.pow(2, size)]
        for i in [0..size]
            ((x >> i) & 1) is 1


printout = (o) ->
    console.log JSON.stringify o


run_cubes = (container) ->
    s = new Space container

    ## add lights
    s.addLight  0,  10,  0, 0xffffff, 1.0, castShadow = true
    s.addLight  0,  0,  1, 0xFF0000, 1.0
    s.addLight  0,  0, -1, 0x00FF00, 1.0
    s.addLight  1,  0,  0, 0x0000FF, 1.0
    s.addLight -1,  0,  0, 0xFFFF00, 1.0

    ## add floor
    floorTexture = THREE.ImageUtils.loadTexture("img/tile.jpg")
    floorTexture.anisotropy = s.renderer.getMaxAnisotropy()
    #floorTexture.wrapS = floorTexture.wrapT = THREE.RepeatWrapping
    #floorTexture.repeat.set 1, 1
    plane = new THREE.Mesh(new THREE.PlaneGeometry(15, 15, 1, 1), new THREE.MeshPhongMaterial(map: floorTexture))
    plane.rotation.x = -Math.PI / 2
    plane.position.y = -3.5
    plane.receiveShadow = true
    s.addToScene plane

    grid = makeGrid spacing: new THREE.Vector3(3, 3, 0), count: new THREE.Vector3(4, 2, 1)
    rotations = makeCombinations 3
    for [gpos, rot] in _.zip grid, rotations
        c = new Cube(s).setPosition(gpos).setRotations((if r then 0.01 else 0) for r in rot)
        s.add c
    s.run window.performance.now()


window.LL = window.LL || {}
window.LL.run_cubes = run_cubes
        